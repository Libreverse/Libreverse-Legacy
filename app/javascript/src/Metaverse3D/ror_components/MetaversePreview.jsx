import {
    Suspense,
    createContext,
    useCallback,
    useContext,
    useEffect,
    useMemo,
    useRef,
    useState,
} from "react";
import { Canvas, useFrame, useThree } from "@react-three/fiber";
import { Physics, usePlane, useSphere } from "@react-three/cannon";
import { Grid, Text } from "@react-three/drei";
import * as THREE from "three";
import {
    EffectComposer,
    SSAO,
    Bloom,
    DepthOfField,
    Vignette,
    Noise,
} from "@react-three/postprocessing";

const initialKeys = Object.freeze({
    w: false,
    a: false,
    s: false,
    d: false,
    space: false,
});

const HotKeysContext = createContext(initialKeys);

const useHotKeys = () => useContext(HotKeysContext);

const HotKeysProvider = ({ children }) => {
    const [keys, setKeys] = useState(initialKeys);

    const handleKeyDown = useCallback((event) => {
        if (event.repeat) return;
        const key = event.key.toLowerCase();

        setKeys((prev) => {
            switch (key) {
                case "w":
                    return prev.w ? prev : { ...prev, w: true };
                case "a":
                    return prev.a ? prev : { ...prev, a: true };
                case "s":
                    return prev.s ? prev : { ...prev, s: true };
                case "d":
                    return prev.d ? prev : { ...prev, d: true };
                case " ":
                case "space":
                    event.preventDefault();
                    return prev.space ? prev : { ...prev, space: true };
                default:
                    return prev;
            }
        });
    }, []);

    const handleKeyUp = useCallback((event) => {
        const key = event.key.toLowerCase();

        setKeys((prev) => {
            switch (key) {
                case "w":
                    return prev.w ? { ...prev, w: false } : prev;
                case "a":
                    return prev.a ? { ...prev, a: false } : prev;
                case "s":
                    return prev.s ? { ...prev, s: false } : prev;
                case "d":
                    return prev.d ? { ...prev, d: false } : prev;
                case " ":
                case "space":
                    return prev.space ? { ...prev, space: false } : prev;
                default:
                    return prev;
            }
        });
    }, []);

    const handleBlur = useCallback(() => {
        setKeys(initialKeys);
    }, []);

    useEffect(() => {
        window.addEventListener("keydown", handleKeyDown);
        window.addEventListener("keyup", handleKeyUp);
        window.addEventListener("blur", handleBlur);

        return () => {
            window.removeEventListener("keydown", handleKeyDown);
            window.removeEventListener("keyup", handleKeyUp);
            window.removeEventListener("blur", handleBlur);
        };
    }, [handleKeyDown, handleKeyUp, handleBlur]);

    return (
        <HotKeysContext.Provider value={keys}>
            {children}
        </HotKeysContext.Provider>
    );
};

const FLOOR_SIZE = 200;

const Floor = () => {
    const [ref] = usePlane(() => ({
        rotation: [-Math.PI / 2, 0, 0],
        position: [0, 0, 0],
        type: "Static",
        collisionFilterGroup: GROUND_GROUP,
        collisionFilterMask: PLAYER_GROUP | OBJECT_GROUP,
        material: { friction: 0.9, restitution: 0.1 },
    }));

    return (
        <mesh ref={ref} receiveShadow visible={false}>
            <planeGeometry args={[FLOOR_SIZE, FLOOR_SIZE]} />
            <meshStandardMaterial
                color="#111118"
                roughness={0.95}
                metalness={0.05}
            />
        </mesh>
    );
};

const Player = () => {
    const keys = useHotKeys();
    const { camera } = useThree();
    const [grounded, setGrounded] = useState(false);
    const velocity = useRef([0, 0, 0]);
    const position = useRef([0, 1.6, 5]);

    const forward = useMemo(() => new THREE.Vector3(), []);
    const right = useMemo(() => new THREE.Vector3(), []);
    const moveDirection = useMemo(() => new THREE.Vector3(), []);
    const worldUp = useMemo(() => new THREE.Vector3(0, 1, 0), []);

    const [ref, api] = useSphere(() => ({
        mass: 1,
        position: [0, 1.6, 5],
        args: [0.5],
        fixedRotation: true,
        allowSleep: true,
        sleepSpeedLimit: 0.1,
        sleepTimeLimit: 1,
        linearDamping: 0.1,
        angularDamping: 0.2,
        collisionFilterGroup: PLAYER_GROUP,
        collisionFilterMask: GROUND_GROUP | OBJECT_GROUP,
        material: { friction: 0.4, restitution: 0.05 },
        onCollideBegin: () => setGrounded(true),
        onCollideEnd: () => setGrounded(false),
    }));

    useEffect(() => {
        const unsubscribeVelocity = api.velocity.subscribe((value) => {
            velocity.current = value;
        });

        const unsubscribePosition = api.position.subscribe((value) => {
            position.current = value;
            camera.position.set(value[0], value[1], value[2]);
        });

        return () => {
            unsubscribeVelocity();
            unsubscribePosition();
        };
    }, [api.position, api.velocity, camera]);

    useFrame(() => {
        camera.getWorldDirection(forward);
        forward.y = 0;
        forward.normalize();

        right.crossVectors(forward, worldUp).normalize();

        moveDirection.set(0, 0, 0);
        if (keys.w) moveDirection.add(forward);
        if (keys.s) moveDirection.sub(forward);
        if (keys.d) moveDirection.add(right);
        if (keys.a) moveDirection.sub(right);

        if (moveDirection.lengthSq() > 0) {
            moveDirection.normalize().multiplyScalar(6);
        }

        let verticalVelocity = velocity.current[1];
        if (keys.space && grounded) {
            verticalVelocity = 10;
            setGrounded(false);
        }

        api.velocity.set(moveDirection.x, verticalVelocity, moveDirection.z);
    });

    return <mesh ref={ref} visible={false} />;
};

const Scene = () => {
    return (
        <>
            <color attach="background" args={["#050507"]} />
            <fog attach="fog" args={["#050507", 20, 80]} />
            <hemisphereLight
                args={["#f8fafc", "#0f172a", 0.4]}
                intensity={0.55}
            />
            <directionalLight
                position={[6, 12, 8]}
                intensity={1.1}
                castShadow
                shadow-mapSize-width={2048}
                shadow-mapSize-height={2048}
                shadow-camera-near={1}
                shadow-camera-far={50}
                shadow-camera-left={-15}
                shadow-camera-right={15}
                shadow-camera-top={15}
                shadow-camera-bottom={-15}
            />
            <ambientLight intensity={0.08} />

            <Grid position={[0, -0.01, 0]} args={[60, 60]} color="#d3d3d3" />

            <Physics
                gravity={[0, -9.81, 0]}
                iterations={12}
                defaultContactMaterial={{ friction: 0.6, restitution: 0.2 }}
            >
                <Floor />
                <Player />
                <MapData />
            </Physics>
            <EffectComposer enableNormalPass depthBuffer multisampling={0}>
                <SSAO />
                <DepthOfField
                    focusDistance={0.01}
                    focalLength={0.2}
                    bokehScale={3}
                    height={480}
                />
                <Bloom intensity={0.5} />
                <Vignette offset={0.1} darkness={0.5} />
                <Noise opacity={0.025} />
            </EffectComposer>
        </>
    );
};

const MouseControls = () => {
    const { camera, gl } = useThree();
    const [isLocked, setIsLocked] = useState(false);
    const canvas = gl.domElement;

    useEffect(() => {
        camera.rotation.order = "YXZ";
    }, [camera]);

    useEffect(() => {
        const handlePointerLockChange = () => {
            setIsLocked(document.pointerLockElement === canvas);
        };
        document.addEventListener("pointerlockchange", handlePointerLockChange);
        return () =>
            document.removeEventListener(
                "pointerlockchange",
                handlePointerLockChange,
            );
    }, [canvas]);

    useEffect(() => {
        if (isLocked) {
            const handleMouseMove = (e) => {
                const movementX = e.movementX || 0;
                const movementY = e.movementY || 0;
                camera.rotation.y -= movementX * 0.002;
                camera.rotation.x -= movementY * 0.001;
                camera.rotation.x = Math.max(
                    -Math.PI / 2,
                    Math.min(Math.PI / 2, camera.rotation.x),
                );
            };
            document.addEventListener("mousemove", handleMouseMove);
            return () =>
                document.removeEventListener("mousemove", handleMouseMove);
        }
    }, [isLocked, camera]);

    return null;
};

const MetaversePreview = () => {
    const [hydrated, setHydrated] = useState(false);
    const canvasRef = useRef();

    useEffect(() => {
        setHydrated(true);
    }, []);

    useEffect(() => {
        const canvas = canvasRef.current;
        if (canvas) {
            const handleMouseMove = (e) => {
                canvas.style.pointerEvents = "none";
                const under = document.elementFromPoint(e.clientX, e.clientY);
                canvas.style.pointerEvents = "auto";
                const panel = under.closest(".metaverse-panel");
                if (
                    under.closest(".metaverse-mode-switch") ||
                    (panel && !panel.classList.contains("is-active"))
                ) {
                    canvas.style.pointerEvents = "none";
                } else {
                    canvas.style.pointerEvents = "auto";
                }
            };
            document.addEventListener("mousemove", handleMouseMove);
            return () =>
                document.removeEventListener("mousemove", handleMouseMove);
        }
    }, []);

    if (!hydrated) return null;

    return (
        <HotKeysProvider>
            <div className="metaverse-expanding-container">
                <Canvas
                    ref={canvasRef}
                    shadows
                    camera={{ position: [0, 1.75, 6], fov: 70 }}
                    dpr={[1, 1.75]}
                    gl={{
                        antialias: true,
                        toneMapping: THREE.ACESFilmicToneMapping,
                    }}
                    style={{ width: "100%", height: "100%" }}
                    onClick={() => {
                        if (canvasRef.current && !document.pointerLockElement) {
                            canvasRef.current.requestPointerLock();
                        }
                    }}
                >
                    <Suspense fallback={null}>
                        <Scene />
                        <MouseControls />
                    </Suspense>
                </Canvas>
            </div>
        </HotKeysProvider>
    );
};

export default MetaversePreview;

const PLAYER_GROUP = 1;
const GROUND_GROUP = 2;
const OBJECT_GROUP = 4;
const PROVIDER_GROUP = 8;

const MapData = () => {
    const [data, setData] = useState(null);

    useEffect(() => {
        fetch("/map/data")
            .then((res) => res.json())
            .then(setData)
            .catch(console.error);
    }, []);

    if (!data) return null;

    return <MapDataInner data={data} />;
};

const MapDataInner = ({ data }) => {
    return (
        <>
            {/* Providers as ground squares */}
            {data.providers?.map((provider, index) => {
                const width =
                    (provider.bbox.x_max - provider.bbox.x_min) * 0.01;
                const depth =
                    (provider.bbox.y_max - provider.bbox.y_min) * 0.01;
                const centerX =
                    (provider.bbox.x_min + provider.bbox.x_max) * 0.005 - 18.8;
                const centerZ =
                    (provider.bbox.y_min + provider.bbox.y_max) * 0.005 - 5.8;
                const [planeRef] = usePlane(() => ({
                    position: [centerX, 0, centerZ],
                    rotation: [-Math.PI / 2, 0, 0],
                    type: "Static",
                    collisionFilterGroup: PROVIDER_GROUP,
                    collisionFilterMask: OBJECT_GROUP,
                }));
                return (
                    <mesh
                        key={`provider-${index}`}
                        ref={planeRef}
                        position={[centerX, 0.01, centerZ]}
                        rotation={[-Math.PI / 2, 0, 0]}
                    >
                        <planeGeometry args={[width, depth]} />
                        <meshStandardMaterial color={provider.color} />
                    </mesh>
                );
            })}
            {/* Experiences as cubes with labels */}
            {data.experiences?.map((experience, index) => {
                const x = experience.mapped_x * 0.01 - 18.8;
                const z = experience.mapped_y * 0.01 - 5.8;
                const y = 0.05;
                return (
                    <group key={`experience-${index}`}>
                        <mesh position={[x, y, z]} castShadow receiveShadow>
                            <boxGeometry args={[0.1, 0.1, 0.1]} />
                            <meshStandardMaterial color={experience.color} />
                        </mesh>
                        <Text
                            position={[x, y + 0.15, z]}
                            fontSize={0.05}
                            color="white"
                            anchorX="center"
                            anchorY="middle"
                            outlineWidth={0.002}
                            outlineColor="black"
                        >
                            {experience.title}
                        </Text>
                    </group>
                );
            })}
        </>
    );
};
