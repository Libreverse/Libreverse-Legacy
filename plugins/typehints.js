// Plain JS plugin that uses the TypeScript checker for inference only.
import * as ts from "typescript";
import { parse } from "@babel/parser";
// Normalize ESM/CJS interop for Babel utils when Vite bundles the config
import traverseModule from "@babel/traverse";
import generateModule from "@babel/generator";
import templateModule from "@babel/template";
import * as t from "@babel/types";
const traverse =
    /** @type {any} */ (
        typeof traverseModule === "function"
            ? traverseModule
            : /** @type {any} */ (traverseModule && traverseModule.default)
    ) || /** fallback noop to avoid hard crash */ function () {}.bind();
const generate = /** @type {any} */ (
    typeof generateModule === "function"
        ? generateModule
        : /** @type {any} */ (generateModule && generateModule.default)
);
const template = /** @type {any} */ (
    typeof templateModule === "function"
        ? templateModule
        : /** @type {any} */ (templateModule && templateModule.default)
);
import fs from "node:fs";

// Compact error output to keep logs short
function compactError(error, id) {
    try {
        const name = error?.name || "Error";
        const baseMessage = error?.message
            ? String(error.message)
            : String(error);
        const firstLine = baseMessage.split("\n")[0].slice(0, 300);
        const loc =
            error?.loc && typeof error.loc.line === "number"
                ? ` (${error.loc.line}:${error.loc.column ?? 0})`
                : "";
        let out = `[vite-plugin-v8-type-hints-with-ts] ${name}${loc} in ${id}: ${firstLine}`;
        if (error?.stack) {
            const frames = String(error.stack)
                .split("\n")
                .slice(1)
                .filter(
                    (l) =>
                        !l.includes("node:internal") &&
                        !l.includes("node_modules"),
                )
                .slice(0, 2);
            if (frames.length > 0) out += "\n" + frames.join("\n");
        }
        const MAX = 600;
        if (out.length > MAX) out = out.slice(0, MAX) + "…";
        return out;
    } catch {
        return `[vite-plugin-v8-type-hints-with-ts] Error in ${id}`;
    }
}

// Helper: human-friendly parameter name
function getParameterName(parameter) {
    return t.isIdentifier(parameter) ? parameter.name : "param";
}

// Map TS type to JSDoc string (handles primitives, arrays, objects, functions)
function ensureContext(context) {
    return (
        context || {
            depth: 0,
            seen: new Set(),
            maxDepth: 3,
            maxProps: 20,
        }
    );
}

function tsTypeToJSDocument(checker, type, context) {
    context = ensureContext(context);
    if (!type) return "any";
    if (context.depth > context.maxDepth) return "any";
    // Cycle guard by id string
    try {
        const id = checker.typeToString(type);
        if (context.seen.has(id)) return "any";
        context.seen.add(id);
    } catch {
        /* ignore */
    }
    const typeString = checker.typeToString(type);
    if (typeString === "number") return "number";
    if (typeString === "string") return "string";
    if (typeString === "boolean") return "boolean";
    // Array-like
    try {
        if (checker.isArrayLikeType && checker.isArrayLikeType(type)) {
            const elementType =
                (checker.getArrayElementType &&
                    checker.getArrayElementType(type)) ||
                (checker.getElementTypeOfArrayType &&
                    checker.getElementTypeOfArrayType(type)) ||
                undefined;
            const element = elementType
                ? tsTypeToJSDocument(checker, elementType, {
                      ...context,
                      depth: context.depth + 1,
                  })
                : "any";
            return `${element}[]`;
        }
    } catch {
        /* ignore */
    }
    // Object-like -> keep footprint tiny
    if ((type.flags & ts.TypeFlags.Object) !== 0) {
        return "object";
    }
    if (type.getCallSignatures && type.getCallSignatures().length > 0)
        return "Function";
    return typeString || "any";
}

// Add coercion AST node (for numbers: | 0; extend as needed)
function addTypeCoercion(path, typeString) {
    if (typeString !== "number") return false;
    const node = path.node;
    let targetNode = node.init || node.argument || node.expression || node.left;
    if (!targetNode) return false;
    // Wrap with | 0 using template to splice an arbitrary expression
    const build = template.expression("((EXPR)) | 0");
    const coerced = build({ EXPR: targetNode });
    if (node.init) node.init = coerced;
    if (node.argument) node.argument = coerced;
    if (node.expression) node.expression = coerced;
    if (node.left) node.left = coerced;
    return true;
}

export default function typehints(options = {}) {
    const {
        includeNodeModules = true,
        enableCoercions = true,
        processEverything = true,
        // Preferred option names (backward compatible mapping applied below)
        variableDocumentation = options.variableDocumentation ??
            options.variableDocs ??
            true,
        objectShapeDocumentation = options.objectShapeDocumentation ??
            options.objectShapeDocs ??
            true,
        maxObjectProperties = options.maxObjectProperties ??
            options.maxObjectProps ??
            8,
        parameterHoistCoercions = options.parameterHoistCoercions ??
            options.paramHoistCoercions ??
            false,
    } = options;

    // Track if we're in build mode to fail builds on errors
    let isBuild = false;

    return {
        name: "vite-plugin-v8-type-hints-with-ts",
        // Only run during static builds
        apply: "build",

        configResolved(config) {
            isBuild = config.command === "build";
        },

        async transform(code, id) {
            // Hard no-op in dev (extra guard; apply: 'build' already limits this)
            if (!isBuild) return;

            // Normalize path and extension
            const cleanId = String(id).split("?")[0];
            if (!/\.([cm]?jsx?)$/i.test(cleanId)) return;
            if (
                !processEverything &&
                !includeNodeModules &&
                cleanId.includes("node_modules")
            )
                return;

            // Skip very large files to avoid heavy TS inference (configurable via env in the future)
            const MAX_FILE_BYTES = 150_000; // ~150 KB
            if (!processEverything) {
                if (code && code.length > MAX_FILE_BYTES) return;
                // Skip common vendor-like dirs in app to avoid deep type recursion
                if (cleanId.includes("/app/javascript/libs/")) return;
                // Skip built dist bundles commonly large in node_modules
                if (cleanId.includes("/dist/") || /\.min\.js$/i.test(cleanId))
                    return;
            }

            try {
                let didChange = false;
                let bailOut = false;
                // Step 1: Create a TS Program that can type-check this JS file
                const compilerOptions = {
                    allowJs: true,
                    checkJs: true,
                    noEmit: true,
                    target: ts.ScriptTarget.Latest,
                    module: ts.ModuleKind.ESNext,
                    strict: false,
                };

                // Normalize id (strip query) and use filesystem host
                const filePath = cleanId;
                const program = ts.createProgram([filePath], compilerOptions);
                const sourceFile =
                    program.getSourceFile(filePath) ||
                    ts.createSourceFile(
                        filePath,
                        fs.existsSync(filePath)
                            ? fs.readFileSync(filePath, "utf8")
                            : code,
                        ts.ScriptTarget.Latest,
                        true,
                        ts.ScriptKind.JS,
                    );
                const checker = program.getTypeChecker();

                // Step 2: Parse Babel AST for transformation (use Babel for code gen)
                const babelAst = parse(code, {
                    sourceType: "module",
                    plugins: [
                        "jsx",
                        "dynamicImport",
                        "importMeta",
                        // Babel 7 supports importAssertions; newer imports may need importAttributes in newer Babel
                        "importAssertions",
                        "topLevelAwait",
                    ],
                    sourceFilename: id,
                });

                // If traverse/generate/template failed to normalize, skip to avoid crashing
                if (typeof traverse !== "function" || !template) {
                    return;
                }

                // Step 3: Traverse Babel AST and infer/add hints using TS checker
                // Note: Map Babel nodes to TS nodes via positions for getTypeAtLocation
                // Utility: create /*! ... */ style block comment only once
                function addBlockDocument(pathOrNode, text) {
                    if (!text) return;
                    const node = pathOrNode.node || pathOrNode; // accept path or node
                    const existing = (node.leadingComments || []).some(
                        (c) =>
                            c.type === "CommentBlock" &&
                            (c.value.includes("@type") ||
                                c.value.includes("@returns")),
                    );
                    if (existing) return;
                    if (pathOrNode.addComment) {
                        pathOrNode.addComment("leading", `! ${text}`, false);
                    } else {
                        // Fallback: push into leadingComments manually
                        node.leadingComments = [
                            ...(node.leadingComments || []),
                            { type: "CommentBlock", value: `! ${text}` },
                        ];
                    }
                }

                // Heuristic object literal shape inference (Babel node based to stay fast)
                function inferObjectShape(babelObjectExpr) {
                    if (!objectShapeDocumentation) return;
                    if (!t.isObjectExpression(babelObjectExpr)) return;
                    const properties = babelObjectExpr.properties.filter(
                        (p) =>
                            t.isObjectProperty(p) &&
                            (t.isIdentifier(p.key) || t.isStringLiteral(p.key)),
                    );
                    if (
                        properties.length === 0 ||
                        properties.length > maxObjectProperties
                    )
                        return;
                    const parts = [];
                    for (const property of properties) {
                        const key = t.isIdentifier(property.key)
                            ? property.key.name
                            : property.key.value;
                        let valueNode = property.value;
                        let typePart = "any";
                        if (t.isNumericLiteral(valueNode)) typePart = "number";
                        else if (t.isStringLiteral(valueNode))
                            typePart = "string";
                        else if (t.isBooleanLiteral(valueNode))
                            typePart = "boolean";
                        else if (t.isNullLiteral(valueNode)) typePart = "any";
                        else if (t.isArrayExpression(valueNode)) {
                            // Simple uniform primitive detection
                            if (valueNode.elements.length === 0)
                                typePart = "any[]";
                            else {
                                const first = valueNode.elements[0];
                                if (t.isNumericLiteral(first))
                                    typePart = "number[]";
                                else if (t.isStringLiteral(first))
                                    typePart = "string[]";
                                else if (t.isBooleanLiteral(first))
                                    typePart = "boolean[]";
                                else typePart = "any[]";
                            }
                        } else if (t.isObjectExpression(valueNode))
                            typePart = "object";
                        else if (t.isTemplateLiteral(valueNode))
                            typePart = "string";
                        else if (
                            t.isUnaryExpression(valueNode) &&
                            valueNode.operator === "+"
                        )
                            typePart = "number";
                        else if (
                            t.isBinaryExpression(valueNode) &&
                            [
                                "+",
                                "-",
                                "*",
                                "/",
                                "%",
                                "|",
                                "&",
                                "^",
                                "<<",
                                ">>",
                                ">>>",
                            ].includes(valueNode.operator)
                        )
                            typePart = "number";
                        else if (t.isCallExpression(valueNode)) {
                            // Heuristic: Math.* => number, String/Number/Boolean constructors
                            if (
                                t.isMemberExpression(valueNode.callee) &&
                                t.isIdentifier(valueNode.callee.object, {
                                    name: "Math",
                                })
                            )
                                typePart = "number";
                            else if (
                                t.isIdentifier(valueNode.callee, {
                                    name: "Number",
                                })
                            )
                                typePart = "number";
                            else if (
                                t.isIdentifier(valueNode.callee, {
                                    name: "String",
                                })
                            )
                                typePart = "string";
                            else if (
                                t.isIdentifier(valueNode.callee, {
                                    name: "Boolean",
                                })
                            )
                                typePart = "boolean";
                        }
                        parts.push(`${key}: ${typePart}`);
                    }
                    if (parts.length === 0) return;
                    return `{ ${parts.join(", ")} }`;
                }

                // Track variable types by identifier name (best-effort) for later param coercion decisions
                const inferredVariableTypes = new Map();

                traverse(babelAst, {
                    FunctionDeclaration(path) {
                        if (!path.node.id) return;
                        const tsNode = findTSNodeAtPosition(
                            sourceFile,
                            path.node.id.start,
                        );
                        if (!tsNode) return;
                        let functionType;
                        try {
                            functionType = checker.getTypeAtLocation(tsNode);
                        } catch {
                            bailOut = true;
                            return;
                        }
                        let sigs;
                        try {
                            sigs = checker.getSignaturesOfType
                                ? checker.getSignaturesOfType(
                                      functionType,
                                      ts.SignatureKind.Call,
                                  )
                                : (functionType.getCallSignatures
                                  ? functionType.getCallSignatures()
                                  : []);
                        } catch {
                            bailOut = true;
                            return;
                        }
                        const sig =
                            sigs && sigs.length > 0 ? sigs[0] : undefined;
                        if (!sig) return;

                        // Params from signature
                        let parameterTypes;
                        try {
                            parameterTypes = sig.parameters.map((parameter) => {
                                const decl =
                                    parameter.valueDeclaration ||
                                    parameter.declarations?.[0];
                                const pType = decl
                                    ? checker.getTypeOfSymbolAtLocation(
                                          parameter,
                                          decl,
                                      )
                                    : undefined;
                                return tsTypeToJSDocument(checker, pType);
                            });
                        } catch {
                            bailOut = true;
                            return;
                        }
                        let returnType = "any";
                        try {
                            returnType = tsTypeToJSDocument(
                                checker,
                                checker.getReturnTypeOfSignature(sig),
                            );
                        } catch {
                            /* ignore */
                        }

                        // Skip emitting when everything is 'any' to minimize footprint
                        const isMeaningful =
                            returnType !== "any" ||
                            parameterTypes.some((t_) => t_ !== "any");
                        if (!isMeaningful) return;

                        // Add JSDoc (preserved by terser via /*! ... */; single-line to minimize size)
                        const parameterDocumentation = path.node.params.map(
                            (parameter, index) =>
                                `@param {${parameterTypes[index] || "any"}} ${getParameterName(parameter)}`,
                        );
                        const document_ = `! ${[...parameterDocumentation, `@returns {${returnType}}`].join(" ")}`;
                        // Only add once
                        const existingLead = path.node.leadingComments || [];
                        const alreadyHasJSDocument = existingLead.some(
                            (c) =>
                                c.type === "CommentBlock" &&
                                (c.value.includes("@returns") ||
                                    c.value.startsWith("!")),
                        );
                        if (!alreadyHasJSDocument) {
                            path.addComment("leading", document_, false); // false => block comment => /*! ... */
                            didChange = true;
                        }

                        // Optional: Inject param coercions at top of function body if enabled
                        if (
                            enableCoercions &&
                            parameterHoistCoercions &&
                            path.node.body &&
                            Array.isArray(path.node.params)
                        ) {
                            const coercionStatements = [];
                            let index = 0;
                            for (const p of path.node.params) {
                                if (
                                    parameterTypes[index] === "number" &&
                                    t.isIdentifier(p)
                                ) {
                                    coercionStatements.push(
                                        template.statement(
                                            `${p.name} = (${p.name}) | 0;`,
                                        )(),
                                    );
                                }
                                index += 1;
                            }
                            if (coercionStatements.length > 0) {
                                path.node.body.body.unshift(
                                    ...coercionStatements,
                                );
                                didChange = true;
                            }
                        }

                        // Coerce params/returns if number
                        if (enableCoercions) {
                            path.traverse({
                                BinaryExpression(subPath) {
                                    const parameterNode = path.node.params.find(
                                        (p) =>
                                            t.isIdentifier(p) &&
                                            t.isIdentifier(subPath.node.left) &&
                                            p.name === subPath.node.left.name,
                                    );
                                    if (
                                        parameterNode &&
                                        parameterTypes[
                                            path.node.params.indexOf(
                                                parameterNode,
                                            )
                                        ] === "number" &&
                                        addTypeCoercion(subPath, "number")
                                    )
                                        didChange = true;
                                },
                                ReturnStatement(subPath) {
                                    if (
                                        subPath.node.argument &&
                                        returnType === "number" &&
                                        addTypeCoercion(subPath, "number")
                                    )
                                        didChange = true;
                                },
                            });
                        }
                    },
                    VariableDeclarator(path) {
                        const tsNode = findTSNodeAtPosition(
                            sourceFile,
                            path.node.id.start,
                        );
                        if (!tsNode || !path.node.init) return;
                        let variableType;
                        try {
                            variableType = checker.getTypeAtLocation(tsNode);
                        } catch {
                            return;
                        }
                        const typeString = tsTypeToJSDocument(
                            checker,
                            variableType,
                        );
                        if (t.isIdentifier(path.node.id)) {
                            inferredVariableTypes.set(
                                path.node.id.name,
                                typeString,
                            );
                        }
                        // Add variable level JSDoc if enabled & meaningful
                        if (
                            variableDocumentation &&
                            t.isIdentifier(path.node.id)
                        ) {
                            let documentType = typeString;
                            // Refine for object literal when generic 'object'
                            if (
                                documentType === "object" &&
                                objectShapeDocumentation &&
                                t.isObjectExpression(path.node.init)
                            ) {
                                const shape = inferObjectShape(path.node.init);
                                if (shape) documentType = shape;
                            }
                            // Refine for arrays of simple primitives from literal
                            if (t.isArrayExpression(path.node.init)) {
                                if (path.node.init.elements.length === 0)
                                    documentType = "any[]";
                                else {
                                    const first = path.node.init.elements[0];
                                    if (t.isNumericLiteral(first))
                                        documentType = "number[]";
                                    else if (t.isStringLiteral(first))
                                        documentType = "string[]";
                                    else if (t.isBooleanLiteral(first))
                                        documentType = "boolean[]";
                                    else documentType = "any[]";
                                }
                            }
                            if (documentType && documentType !== "any") {
                                addBlockDocument(
                                    path,
                                    `@type {${documentType}}`,
                                );
                                didChange = true;
                            }
                        }
                        if (
                            enableCoercions &&
                            typeString === "number" &&
                            addTypeCoercion(path, "number")
                        )
                            didChange = true;
                    },
                    ForOfStatement(path) {
                        let leftId;
                        if (t.isVariableDeclaration(path.node.left)) {
                            const first = path.node.left.declarations?.[0];
                            if (first && t.isIdentifier(first.id))
                                leftId = first.id;
                        } else if (t.isIdentifier(path.node.left)) {
                            leftId = path.node.left;
                        }
                        if (!leftId) return;
                        const rightTSNode = findTSNodeAtPosition(
                            sourceFile,
                            path.node.right.start,
                        );
                        if (!rightTSNode) return;
                        let arrayType;
                        try {
                            arrayType = checker.getTypeAtLocation(rightTSNode);
                        } catch {
                            return;
                        }
                        let elementType;
                        try {
                            elementType =
                                (checker.getArrayElementType &&
                                    checker.getArrayElementType(arrayType)) ||
                                (checker.getElementTypeOfArrayType &&
                                    checker.getElementTypeOfArrayType(
                                        arrayType,
                                    )) ||
                                undefined;
                        } catch {
                            /* ignore */
                        }
                        const elementString = tsTypeToJSDocument(
                            checker,
                            elementType,
                        );
                        if (enableCoercions && elementString === "number") {
                            path.traverse({
                                BinaryExpression(subPath) {
                                    if (
                                        t.isIdentifier(subPath.node.left) &&
                                        t.isIdentifier(leftId) &&
                                        subPath.node.left.name ===
                                            leftId.name &&
                                        addTypeCoercion(subPath, "number")
                                    )
                                        didChange = true;
                                },
                            });
                        }
                    },
                    // Deopt warning: Dynamic props
                    AssignmentExpression(path) {
                        if (
                            path.node.left?.computed &&
                            path.node.left.property?.type !== "Identifier"
                        ) {
                            /*
                            const line =
                                path.node.loc && path.node.loc.start
                                    ? path.node.loc.start.line
                                    : "?";
                            console.warn(
                                `Potential V8 deoptimization: Dynamic property at line ${line}`,
                            );
                            */
                        }
                    },
                });

                // Helper: Find TS node at Babel position (approximate via pos)
                function findTSNodeAtPosition(sourceFile, pos) {
                    let result;
                    function visit(node) {
                        if (pos < node.pos || pos >= node.end) return;
                        result = node;
                        node.forEachChild(visit);
                    }
                    visit(sourceFile);
                    return result;
                }

                if (bailOut || !didChange) return;
                // Step 4: Generate transformed code with source map (only if changed)
                const { code: transformedCode, map } = generate(babelAst, {
                    sourceMaps: true,
                    sourceFileName: id,
                });

                return {
                    code: transformedCode,
                    map,
                };
            } catch (error) {
                const error_ =
                    error instanceof Error ? error : new Error(String(error));
                if (isBuild) {
                    // Fail the build with compact message
                    this.error(compactError(error_, id));
                } else {
                    // Keep dev server running with compact message
                    console.error(compactError(error_, id));
                }
                return; // Graceful fallback in dev
            }
        },
        // No HMR behavior; plugin only applies in build
    };
}
