/* eslint-disable unicorn/no-this-assignment, unicorn/no-null, unicorn/no-array-for-each, unicorn/no-array-method-this-argument, unicorn/no-for-loop, no-redeclare, unicorn/prefer-number-properties, unicorn/no-new-array, unicorn/prefer-query-selector -- Third-party rainyday.js library with legacy patterns */

/*
GNU GENERAL PUBLIC LICENSE
                       Version 2, June 1991

 Copyright (C) 1989, 1991 Free Software Foundation, Inc.,
 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

                            Preamble

  The licenses for most software are designed to take away your
freedom to share and change it.  By contrast, the GNU General Public
License is intended to guarantee your freedom to share and change free
software--to make sure the software is free for all its users.  This
General Public License applies to most of the Free Software
Foundation's software and to any other program whose authors commit to
using it.  (Some other Free Software Foundation software is covered by
the GNU Lesser General Public License instead.)  You can apply it to
your programs, too.

  When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
this service if you wish), that you receive source code or can get it
if you want it, that you can change the software or use pieces of it
in new free programs; and that you know you can do these things.

  To protect your rights, we need to make restrictions that forbid
anyone to deny you these rights or to ask you to surrender the rights.
These restrictions translate to certain responsibilities for you if you
distribute copies of the software, or if you modify it.

  For example, if you distribute copies of such a program, whether
gratis or for a fee, you must give the recipients all the rights that
you have.  You must make sure that they, too, receive or can get the
source code.  And you must show them these terms so they know their
rights.

  We protect your rights with two steps: (1) copyright the software, and
(2) offer you this license which gives you legal permission to copy,
distribute and/or modify the software.

  Also, for each author's protection and ours, we want to make certain
that everyone understands that there is no warranty for this free
software.  If the software is modified by someone else and passed on, we
want its recipients to know that what they have is not the original, so
that any problems introduced by others will not reflect on the original
authors' reputations.

  Finally, any free program is threatened constantly by software
patents.  We wish to avoid the danger that redistributors of a free
program will individually obtain patent licenses, in effect making the
program proprietary.  To prevent this, we have made it clear that any
patent must be licensed for everyone's free use or not licensed at all.

  The precise terms and conditions for copying, distribution and
modification follow.

                    GNU GENERAL PUBLIC LICENSE
   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

  0. This License applies to any program or other work which contains
a notice placed by the copyright holder saying it may be distributed
under the terms of this General Public License.  The "Program", below,
refers to any such program or work, and a "work based on the Program"
means either the Program or any derivative work under copyright law:
that is to say, a work containing the Program or a portion of it,
either verbatim or with modifications and/or translated into another
language.  (Hereinafter, translation is included without limitation in
the term "modification".)  Each licensee is addressed as "you".

Activities other than copying, distribution and modification are not
covered by this License; they are outside its scope.  The act of
running the Program is not restricted, and the output from the Program
is covered only if its contents constitute a work based on the
Program (independent of having been made by running the Program).
Whether that is true depends on what the Program does.

  1. You may copy and distribute verbatim copies of the Program's
source code as you receive it, in any medium, provided that you
conspicuously and appropriately publish on each copy an appropriate
copyright notice and disclaimer of warranty; keep intact all the
notices that refer to this License and to the absence of any warranty;
and give any other recipients of the Program a copy of this License
along with the Program.

You may charge a fee for the physical act of transferring a copy, and
you may at your option offer warranty protection in exchange for a fee.

  2. You may modify your copy or copies of the Program or any portion
of it, thus forming a work based on the Program, and copy and
distribute such modifications or work under the terms of Section 1
above, provided that you also meet all of these conditions:

    a) You must cause the modified files to carry prominent notices
    stating that you changed the files and the date of any change.

    b) You must cause any work that you distribute or publish, that in
    whole or in part contains or is derived from the Program or any
    part thereof, to be licensed as a whole at no charge to all third
    parties under the terms of this License.

    c) If the modified program normally reads commands interactively
    when run, you must cause it, when started running for such
    interactive use in the most ordinary way, to print or display an
    announcement including an appropriate copyright notice and a
    notice that there is no warranty (or else, saying that you provide
    a warranty) and that users may redistribute the program under
    these conditions, and telling the user how to view a copy of this
    License.  (Exception: if the Program itself is interactive but
    does not normally print such an announcement, your work based on
    the Program is not required to print an announcement.)

These requirements apply to the modified work as a whole.  If
identifiable sections of that work are not derived from the Program,
and can be reasonably considered independent and separate works in
themselves, then this License, and its terms, do not apply to those
sections when you distribute them as separate works.  But when you
distribute the same sections as part of a whole which is a work based
on the Program, the distribution of the whole must be on the terms of
this License, whose permissions for other licensees extend to the
entire whole, and thus to each and every part regardless of who wrote it.

Thus, it is not the intent of this section to claim rights or contest
your rights to work written entirely by you; rather, the intent is to
exercise the right to control the distribution of derivative or
collective works based on the Program.

In addition, mere aggregation of another work not based on the Program
with the Program (or with a work based on the Program) on a volume of
a storage or distribution medium does not bring the other work under
the scope of this License.

  3. You may copy and distribute the Program (or a work based on it,
under Section 2) in object code or executable form under the terms of
Sections 1 and 2 above provided that you also do one of the following:

    a) Accompany it with the complete corresponding machine-readable
    source code, which must be distributed under the terms of Sections
    1 and 2 above on a medium customarily used for software interchange; or,

    b) Accompany it with a written offer, valid for at least three
    years, to give any third party, for a charge no more than your
    cost of physically performing source distribution, a complete
    machine-readable copy of the corresponding source code, to be
    distributed under the terms of Sections 1 and 2 above on a medium
    customarily used for software interchange; or,

    c) Accompany it with the information you received as to the offer
    to distribute corresponding source code.  (This alternative is
    allowed only for noncommercial distribution and only if you
    received the program in object code or executable form with such
    an offer, in accord with Subsection b above.)

The source code for a work means the preferred form of the work for
making modifications to it.  For an executable work, complete source
code means all the source code for all modules it contains, plus any
associated interface definition files, plus the scripts used to
control compilation and installation of the executable.  However, as a
special exception, the source code distributed need not include
anything that is normally distributed (in either source or binary
form) with the major components (compiler, kernel, and so on) of the
operating system on which the executable runs, unless that component
itself accompanies the executable.

If distribution of executable or object code is made by offering
access to copy from a designated place, then offering equivalent
access to copy the source code from the same place counts as
distribution of the source code, even though third parties are not
compelled to copy the source along with the object code.

  4. You may not copy, modify, sublicense, or distribute the Program
except as expressly provided under this License.  Any attempt
otherwise to copy, modify, sublicense or distribute the Program is
void, and will automatically terminate your rights under this License.
However, parties who have received copies, or rights, from you under
this License will not have their licenses terminated so long as such
parties remain in full compliance.

  5. You are not required to accept this License, since you have not
signed it.  However, nothing else grants you permission to modify or
distribute the Program or its derivative works.  These actions are
prohibited by law if you do not accept this License.  Therefore, by
modifying or distributing the Program (or any work based on the
Program), you indicate your acceptance of this License to do so, and
all its terms and conditions for copying, distributing or modifying
the Program or works based on it.

  6. Each time you redistribute the Program (or any work based on the
Program), the recipient automatically receives a license from the
original licensor to copy, distribute or modify the Program subject to
these terms and conditions.  You may not impose any further
restrictions on the recipients' exercise of the rights granted herein.
You are not responsible for enforcing compliance by third parties to
this License.

  7. If, as a consequence of a court judgment or allegation of patent
infringement or for any other reason (not limited to patent issues),
conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot
distribute so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you
may not distribute the Program at all.  For example, if a patent
license would not permit royalty-free redistribution of the Program by
all those who receive copies directly or indirectly through you, then
the only way you could satisfy both it and this License would be to
refrain entirely from distribution of the Program.

If any portion of this section is held invalid or unenforceable under
any particular circumstance, the balance of the section is intended to
apply and the section as a whole is intended to apply in other
circumstances.

It is not the purpose of this section to induce you to infringe any
patents or other property right claims or to contest validity of any
such claims; this section has the sole purpose of protecting the
integrity of the free software distribution system, which is
implemented by public license practices.  Many people have made
generous contributions to the wide range of software distributed
through that system in reliance on consistent application of that
system; it is up to the author/donor to decide if he or she is willing
to distribute software through any other system and a licensee cannot
impose that choice.

This section is intended to make thoroughly clear what is believed to
be a consequence of the rest of this License.

  8. If the distribution and/or use of the Program is restricted in
certain countries either by patents or by copyrighted interfaces, the
original copyright holder who places the Program under this License
may add an explicit geographical distribution limitation excluding
those countries, so that distribution is permitted only in or among
countries not thus excluded.  In such case, this License incorporates
the limitation as if written in the body of this License.

  9. The Free Software Foundation may publish revised and/or new versions
of the General Public License from time to time.  Such new versions will
be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

Each version is given a distinguishing version number.  If the Program
specifies a version number of this License which applies to it and "any
later version", you have the option of following the terms and conditions
either of that version or of any later version published by the Free
Software Foundation.  If the Program does not specify a version number of
this License, you may choose any version ever published by the Free Software
Foundation.

  10. If you wish to incorporate parts of the Program into other free
programs whose distribution conditions are different, write to the author
to ask for permission.  For software which is copyrighted by the Free
Software Foundation, write to the Free Software Foundation; we sometimes
make exceptions for this.  Our decision will be guided by the two goals
of preserving the free status of all derivatives of our free software and
of promoting the sharing and reuse of software generally.

                            NO WARRANTY

  11. BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW.  EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE ENTIRE RISK AS
TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU.  SHOULD THE
PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
REPAIR OR CORRECTION.

  12. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED
TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY
YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER
PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

                     END OF TERMS AND CONDITIONS

            How to Apply These Terms to Your New Programs

  If you develop a new program, and you want it to be of the greatest
possible use to the public, the best way to achieve this is to make it
free software which everyone can redistribute and change under these terms.

  To do so, attach the following notices to the program.  It is safest
to attach them to the start of each source file to most effectively
convey the exclusion of warranty; and each file should have at least
the "copyright" line and a pointer to where the full notice is found.

    {{description}}
    Copyright (C) {{year}}  {{fullname}}

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

Also add information on how to contact you by electronic and paper mail.

If the program is interactive, make it output a short notice like this
when it starts in an interactive mode:

    Gnomovision version 69, Copyright (C) year name of author
    Gnomovision comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
    This is free software, and you are welcome to redistribute it
    under certain conditions; type `show c' for details.

The hypothetical commands `show w' and `show c' should show the appropriate
parts of the General Public License.  Of course, the commands you use may
be called something other than `show w' and `show c'; they could even be
mouse-clicks or menu items--whatever suits your program.

You should also get your employer (if you work as a programmer) or your
school, if any, to sign a "copyright disclaimer" for the program, if
necessary.  Here is a sample; alter the names:

  Yoyodyne, Inc., hereby disclaims all copyright interest in the program
  `Gnomovision' (which makes passes at compilers) written by James Hacker.

  {signature of Ty Coon}, 1 April 1989
  Ty Coon, President of Vice

This General Public License does not permit incorporating your program into
proprietary programs.  If your program is a subroutine library, you may
consider it more useful to permit linking proprietary applications with the
library.  If this is what you want to do, use the GNU Lesser General
Public License instead of this License.
*/

/**
 * Defines a new instance of the rainyday.js.
 * @param options options element with script parameters
 */

function RainyDay(options) {
    if (this === globalThis) {
        // if *this* is the window object, start over with a *new* object
        return new RainyDay(options);
    }

    var source =
        typeof options.image === "string"
            ? document.querySelector(`#${options.image}`)
            : options.image;

    if (source.tagName.toLowerCase() === "img") {
        this.imgSource = undefined;
        this.img = source;
        this.initialize(options);
    } else {
        var self = this;
        var style =
            source.currentStyle ||
            globalThis.getComputedStyle(source, false),
            bi = style.backgroundImage.slice(4, -1).replaceAll('"', "");

        var imgTemporary = document.createElement("img");
        imgTemporary.addEventListener("load", function () {
            self.imgSource = source;
            self.img = this;
            self.initialize(options);
        });
        imgTemporary.src = bi;
        // backup bck url
        self.bckStyle = style;
    }
}

/**
 * Destroy RainyDay.js
 */
RainyDay.prototype.destroy = function () {
    // Stop animation
    this.pause();

    // Remove event listeners
    if (this._onResize) {
        window.removeEventListener("resize", this._onResize);
        globalThis.removeEventListener("orientationchange", this._onResize);
        this._onResize = null;
    }

    // Remove canvas from DOM
    if (this.canvas && this.canvas.remove) {
        this.canvas.remove();
    }

    // Stop audio playback
    if (this.audio) {
        this.audio.pause();
        this.audio = null;
    }

    // Restore original image styles or background
    if (this.originalStyles && this.imgSource) {
        var s = this.originalStyles;
        this.imgSource.style.zIndex = s.zIndex;
        this.imgSource.style.position = s.position;
        this.imgSource.style.top = s.top;
        this.imgSource.style.left = s.left;
        this.imgSource.style.width = s.width;
        this.imgSource.style.height = s.height;
        this.imgSource.style.background = s.background;
    } else if (this.bckStyle && this.imgSource) {
        this.imgSource.style.background = this.bckStyle.background;
    }

    // Clean up all properties
    Object.keys(this).forEach(function (item) {
        delete this[item];
    }, this);
};

/**
 * Initialize options
 */

RainyDay.prototype.initialize = function (options) {
    var sourceParent =
        this.imgSource ||
        options.parentElement ||
        document.querySelectorAll("body")[0];
    var parentOffset = globalThis.getOffset(sourceParent);

    this.imgDownscaled = this.customDrop || downscaleImage(this.img, 50);
    if (options.sound) {
        this.audio = playSound(options.sound);
    }

    var defaults = {
        opacity: 1,
        blur: 10,
        crop: [0, 0, this.img.naturalWidth, this.img.naturalHeight],
        enableSizeChange: true,
        parentElement: sourceParent,
        fps: 24,
        fillStyle: "#8ED6FF",
        enableCollisions: true,
        gravityThreshold: 3,
        gravityAngle: Math.PI / 2,
        gravityAngleVariance: 0,
        reflectionScaledownFactor: 5,
        reflectionDropMappingWidth: 200,
        reflectionDropMappingHeight: 200,
        width: sourceParent.clientWidth,
        height: sourceParent.clientHeight,
        position: "absolute",
        top: parentOffset.top + "px",
        left: parentOffset.left + "px",
    };

    // add the defaults to options
    for (var option in defaults) {
        if (options[option] === undefined) {
            options[option] = defaults[option];
        }
    }
    this.options = options;

    this.drops = [];

    // prepare canvas elements
    this.canvas = this.options.canvas || this.prepareCanvas();
    this.prepareBackground();
    this.prepareGlass();

    // assume defaults
    this.reflection = this.REFLECTION_MINIATURE;
    this.trail = this.TRAIL_DROPS;
    this.gravity = this.GRAVITY_NON_LINEAR;
    this.collision = this.COLLISION_SIMPLE;

    // set polyfill of requestAnimationFrame
    this.setRequestAnimFrame();

    // Start rain engine
    this.rain([[3, 5, 0.5]], 50);
};

/**
 * Create the main canvas over a given element
 * @returns HTMLElement the canvas
 */
RainyDay.prototype.prepareCanvas = function () {
    var canvas = document.createElement("canvas");
    var { position, top, left, width, height } = this.options;
    canvas.style.position = position;
    canvas.style.top = top;
    canvas.style.left = left;
    canvas.width = width;
    canvas.height = height;
    if (this.img.style.zIndex) {
        canvas.style.zIndex = this.img.style.zIndex;
        this.img.style.zIndex += 1;
    } else {
        canvas.style.zIndex = 99;
    }
    if (this.imgSource) {
        this.options.parentElement.parentNode.insertBefore(
            canvas,
            this.imgSource,
        );

        // Backup original styles to restore on destroy
        this.originalStyles = {
            zIndex: this.imgSource.style.zIndex,
            position: this.imgSource.style.position,
            top: this.imgSource.style.top,
            left: this.imgSource.style.left,
            width: this.imgSource.style.width,
            height: this.imgSource.style.height,
            background: this.imgSource.style.background,
        };

        // Set styles for rain effect
        this.imgSource.style.zIndex = 100;
        this.imgSource.style.position = position;
        this.imgSource.style.top = top;
        this.imgSource.style.left = left;
        this.imgSource.style.width = width + "px";
        this.imgSource.style.height = height + "px";
        this.imgSource.style.background = "none";
    } else {
        this.options.parentElement.append(canvas);
    }

    //this.options.parentElement.parentNode.style.position = 'relative'
    this.options.parentElement.parentNode.style.height =
        this.options.height + "px";

    if (this.options.enableSizeChange) {
        this.setResizeHandler();
    }
    return canvas;
};

RainyDay.prototype.setResizeHandler = function () {
    // Store bound listener to remove later
    this._onResize = this.checkSize.bind(this);
    window.addEventListener("resize", this._onResize);
    globalThis.addEventListener("orientationchange", this._onResize);
};

/**
 * Periodically check the size of the underlying element
 */
RainyDay.prototype.checkSize = function () {
    var { width, height, offsetLeft, offsetTop } = this.canvas;

    var source = this.options.parentElement.getBoundingClientRect();
    var sourceWidth = source.width;
    var sourceHeight = source.bottom - source.top;

    var clientWidth = sourceWidth;
    var clientHeight = sourceHeight;
    var clientOffsetLeft = source.left;
    var clientOffsetTop = source.top;

    var canvasWidth = width;
    var canvasHeight = height;
    var canvasOffsetLeft = offsetLeft;
    var canvasOffsetTop = offsetTop;

    if (this.options.parentElement.style.zIndex) {
        this.canvas.style.zIndex = this.options.parentElement.style.zIndex;
    }

    if (canvasWidth !== clientWidth || canvasHeight !== clientHeight) {
        width = clientWidth;
        height = clientHeight;
        this.glass.width = width;
        this.glass.height = height;
        this.prepareBackground();
        this.prepareReflections();
    }

    if (
        canvasOffsetLeft !== clientOffsetLeft ||
        canvasOffsetTop !== clientOffsetTop
    ) {
        this.canvas.style.left = clientOffsetLeft;
        this.canvas.style.top = clientOffsetTop;
    }
};

/**
 * Start animation loop
 */
RainyDay.prototype.animateDrops = function () {
    if (!Array.isArray(this.drops)) return;

    if (this.addDropCallback) {
        this.addDropCallback();
    }
    // |this.drops| array may be changed as we iterate over drops
    var dropsClone = [...this.drops];
    var newDrops = [];
    for (const element of dropsClone) {
        if (element.animate()) {
            newDrops.push(element);
        }
    }
    this.drops = newDrops;
    this.requestID = globalThis.requestAnimFrame(this.animateDrops.bind(this));
};

RainyDay.prototype.pause = function () {
    globalThis.cancelAnimationFrame(this.requestID);
};

RainyDay.prototype.resume = function () {
    this.requestID = globalThis.requestAnimFrame(this.animateDrops.bind(this));
};

/**
 * Polyfill for requestAnimationFrame
 */
RainyDay.prototype.setRequestAnimFrame = function () {
    var fps = this.options.fps;
    globalThis.requestAnimFrame = (function () {
        return (
            globalThis.requestAnimationFrame ||
            globalThis.webkitRequestAnimationFrame ||
            globalThis.mozRequestAnimationFrame ||
            function (callback) {
                globalThis.setTimeout(callback, 1000 / fps);
            }
        );
    })();
};

/**
 * Create the helper canvas for rendering raindrop reflections.
 */
RainyDay.prototype.prepareReflections = function () {
    this.reflected = document.createElement("canvas");
    this.reflected.width = Math.floor(
        this.canvas.width / this.options.reflectionScaledownFactor,
    );
    this.reflected.height = Math.floor(
        this.canvas.height / this.options.reflectionScaledownFactor,
    );
    var context = this.reflected.getContext("2d");
    context.drawImage(
        this.imgDownscaled,
        0,
        0,
        this.imgDownscaled.width,
        this.imgDownscaled.height,
        0,
        0,
        this.reflected.width,
        this.reflected.height,
    );
};

/**
 * Create the glass canvas.
 */
RainyDay.prototype.prepareGlass = function () {
    this.glass = document.createElement("canvas");
    this.glass.width = this.canvas.width;
    this.glass.height = this.canvas.height;
    this.context = this.glass.getContext("2d");
    this.context.filter = "blur(1.5px)";
};

/**
 * Main function for starting rain rendering.
 * @param presets list of presets to be applied
 * @param speed speed of the animation (if not provided or 0 static image will be generated)
 */
RainyDay.prototype.rain = function (presets, speed) {
    // prepare canvas for drop reflections
    if (this.reflection !== this.REFLECTION_NONE) {
        this.prepareReflections();
    }

    this.animateDrops();

    // animation
    this.presets = presets;

    this.PRIVATE_GRAVITY_FORCE_FACTOR_Y = (this.options.fps * 0.001) / 25;
    this.PRIVATE_GRAVITY_FORCE_FACTOR_X =
        ((Math.PI / 2 - this.options.gravityAngle) *
            (this.options.fps * 0.001)) /
        50;

    // prepare gravity matrix
    if (this.options.enableCollisions) {
        // calculate max radius of a drop to establish gravity matrix resolution
        var maxDropRadius = 0;
        for (var index = 0; index < presets.length; index++) {
            if (presets[index][0] + presets[index][1] > maxDropRadius) {
                maxDropRadius = Math.floor(
                    presets[index][0] + presets[index][1],
                );
            }
        }

        if (maxDropRadius > 0) {
            // initialize the gravity matrix
            var mwi = Math.ceil(this.canvas.width / maxDropRadius);
            var mhi = Math.ceil(this.canvas.height / maxDropRadius);
            this.matrix = new CollisionMatrix(mwi, mhi, maxDropRadius);
        } else {
            this.options.enableCollisions = false;
        }
    }

    for (var index = 0; index < presets.length; index++) {
        if (!presets[index][3]) {
            presets[index][3] = -1;
        }
    }

    var lastExecutionTime = 0;
    this.addDropCallback = function () {
        var timestamp = Date.now();
        if (timestamp - lastExecutionTime < speed) {
            return;
        }
        lastExecutionTime = timestamp;
        var context = this.canvas.getContext("2d");
        context.clearRect(0, 0, this.canvas.width, this.canvas.height);
        context.drawImage(
            this.background,
            0,
            0,
            this.canvas.width,
            this.canvas.height,
        );
        // select matching preset
        var preset;
        for (const preset_ of presets) {
            if (preset_[2] > 1 || preset_[3] === -1) {
                if (preset_[3] !== 0) {
                    preset_[3]--;
                    for (var y = 0; y < preset_[2]; ++y) {
                        this.putDrop(
                            new Drop(
                                this,
                                Math.random() * this.canvas.width,
                                Math.random() * this.canvas.height,
                                preset_[0],
                                preset_[1],
                            ),
                        );
                    }
                }
            } else if (Math.random() < preset_[2]) {
                preset = preset_;
                break;
            }
        }
        if (preset) {
            this.putDrop(
                new Drop(
                    this,
                    Math.random() * this.canvas.width,
                    Math.random() * this.canvas.height,
                    preset[0],
                    preset[1],
                ),
            );
        }
        context.save();
        context.globalAlpha = this.options.opacity;
        context.drawImage(
            this.glass,
            0,
            0,
            this.canvas.width,
            this.canvas.height,
        );
        context.restore();
    }.bind(this);
};

/**
 * Adds a new raindrop to the animation.
 * @param drop drop object to be added to the animation
 */
RainyDay.prototype.putDrop = function (drop) {
    drop.draw();
    if (this.gravity && drop.r > this.options.gravityThreshold) {
        if (this.options.enableCollisions) {
            this.matrix.update(drop);
        }
        this.drops.push(drop);
    }
};

/**
 * Clear the drop and remove from the list if applicable.
 * @drop to be cleared
 * @force force removal from the list
 * result if true animation of this drop should be stopped
 */
RainyDay.prototype.clearDrop = function (drop, force) {
    var result = drop.clear(force);
    if (result) {
        var index = this.drops.indexOf(drop);
        if (index >= 0) {
            this.drops.splice(index, 1);
        }
    }
    return result;
};

/**
 * Defines a new raindrop object.
 * @param rainyday reference to the parent object
 * @param centerX x position of the center of this drop
 * @param centerY y position of the center of this drop
 * @param min minimum size of a drop
 * @param base base value for randomizing drop size
 */

function Drop(rainyday, centerX, centerY, min, base) {
    this.x = Math.floor(centerX);
    this.y = Math.floor(centerY);
    this.r = Math.ceil(Math.random() * base + min);
    this.rainyday = rainyday;
    this.context = rainyday.context;
    this.reflection = rainyday.reflected;
}

/**
 * Draws a raindrop on canvas at the current position.
 */
Drop.prototype.draw = function () {
    this.context.save();
    this.context.beginPath();

    var orgR = this.r;
    this.r = Math.floor(0.95 * this.r);
    if (this.r < 3) {
        this.context.arc(this.x, this.y, this.r, 0, Math.PI * 2, true);
        this.context.closePath();
    } else if (this.colliding || this.yspeed > 2) {
        if (this.colliding) {
            var collider = this.colliding;
            this.r = 1.001 * Math.max(this.r, collider.r);
            this.x += collider.x - this.x;
            this.colliding = null;
        }

        var yr = 1 + 0.1 * this.yspeed;
        this.context.moveTo(this.x - this.r / yr, this.y);
        this.context.bezierCurveTo(
            this.x - this.r,
            this.y - this.r * 2,
            this.x + this.r,
            this.y - this.r * 2,
            this.x + this.r / yr,
            this.y,
        );
        this.context.bezierCurveTo(
            this.x + this.r,
            this.y + yr * this.r,
            this.x - this.r,
            this.y + yr * this.r,
            this.x - this.r / yr,
            this.y,
        );
    } else {
        this.context.arc(this.x, this.y, this.r * 0.9, 0, Math.PI * 2, true);
        this.context.closePath();
    }

    this.context.clip();

    this.r = orgR;

    if (this.rainyday.reflection) {
        this.rainyday.reflection(this);
    }

    this.context.restore();
};

/**
 * Clears the raindrop region.
 * @param force force stop
 * @returns Boolean true if the animation is stopped
 */

Drop.prototype.clear = function (force) {
    this.context.clearRect(
        this.x - this.r - 1,
        this.y - this.r - 2,
        2 * this.r + 2,
        2 * this.r + 2,
    );

    if (force) {
        this.terminate = true;
        return true;
    }
    if (
        this.y - this.r > this.rainyday.canvas.height ||
        this.x - this.r > this.rainyday.canvas.width ||
        this.x + this.r < 0
    ) {
        // over edge so stop this drop
        return true;
    }
    return false;
};

/**
 * Moves the raindrop to a new position according to the gravity.
 */
Drop.prototype.animate = function () {
    if (this.terminate) {
        return false;
    }

    var stopped = this.rainyday.gravity(this);
    if (!stopped && this.rainyday.trail) {
        this.rainyday.trail(this);
    }
    if (this.rainyday.options.enableCollisions) {
        var collisions = this.rainyday.matrix.update(this, stopped);
        if (collisions) {
            this.rainyday.collision(this, collisions);
        }
    }
    return !stopped || this.terminate;
};

/**
 * TRAIL function: no trail at all
 */
RainyDay.prototype.TRAIL_NONE = function () {
    // nothing going on here
};

/**
 * TRAIL function: trail of small drops (default)
 * @param drop raindrop object
 */
RainyDay.prototype.TRAIL_DROPS = function (drop) {
    if (!drop.trailY || drop.y - drop.trailY >= Math.random() * 100 * drop.r) {
        drop.trailY = drop.y;
        this.putDrop(
            new Drop(
                this,
                Math.floor(drop.x + (Math.random() * 2 - 1) * Math.random()),
                drop.y - drop.r - 5,
                Math.ceil(drop.r / 5),
                0,
            ),
        );
    }
};

/**
 * TRAIL function: trail of unblurred image
 * @param drop raindrop object
 */
RainyDay.prototype.TRAIL_SMUDGE = function (drop) {
    var y = drop.y - drop.r - 3;
    var x = drop.x - Math.floor(drop.r / 2) + Math.random() * 2;
    if (y < 0 || x < 0) {
        return;
    }
    this.context.drawImage(
        this.clearbackground,
        x,
        y,
        drop.r,
        2,
        x,
        y,
        drop.r,
        2,
    );
};

/**
 * GRAVITY function: no gravity at all
 * @returns Boolean true if the animation is stopped
 */
RainyDay.prototype.GRAVITY_NONE = function () {
    return true;
};

/**
 * GRAVITY function: linear gravity
 * @param drop raindrop object
 * @returns Boolean true if the animation is stopped
 */
RainyDay.prototype.GRAVITY_LINEAR = function (drop) {
    if (this.clearDrop(drop)) {
        return true;
    }

    if (drop.yspeed) {
        drop.yspeed += this.PRIVATE_GRAVITY_FORCE_FACTOR_Y * Math.floor(drop.r);
        drop.xspeed += Math.floor(
            this.PRIVATE_GRAVITY_FORCE_FACTOR_X * Math.floor(drop.r),
        );
    } else {
        drop.yspeed = this.PRIVATE_GRAVITY_FORCE_FACTOR_Y;
        drop.xspeed = Math.floor(this.PRIVATE_GRAVITY_FORCE_FACTOR_X);
    }

    drop.y += Math.floor(drop.yspeed);
    drop.draw();
    return false;
};

/**
 * GRAVITY function: non-linear gravity (default)
 * @param drop raindrop object
 * @returns Boolean true if the animation is stopped
 */
RainyDay.prototype.GRAVITY_NON_LINEAR = function (drop) {
    if (this.clearDrop(drop)) {
        return true;
    }

    if (drop.collided) {
        drop.collided = false;
        drop.seed = Math.floor(drop.r * Math.random() * this.options.fps);
        drop.skipping = false;
        drop.slowing = false;
    } else if (!drop.seed || drop.seed < 0) {
        drop.seed = Math.floor(drop.r * Math.random() * this.options.fps);
        drop.skipping = drop.skipping === false;
        drop.slowing = true;
    }

    drop.seed--;

    if (drop.yspeed) {
        if (drop.slowing) {
            drop.yspeed /= 1.1;
            drop.xspeed /= 1.1;
            if (drop.yspeed < this.PRIVATE_GRAVITY_FORCE_FACTOR_Y) {
                drop.slowing = false;
            }
        } else if (drop.skipping) {
            drop.yspeed = this.PRIVATE_GRAVITY_FORCE_FACTOR_Y;
            drop.xspeed = this.PRIVATE_GRAVITY_FORCE_FACTOR_X;
        } else {
            drop.yspeed +=
                1 * this.PRIVATE_GRAVITY_FORCE_FACTOR_Y * Math.floor(drop.r);
            drop.xspeed +=
                1 * this.PRIVATE_GRAVITY_FORCE_FACTOR_X * Math.floor(drop.r);
        }
    } else {
        drop.yspeed = this.PRIVATE_GRAVITY_FORCE_FACTOR_Y;
        drop.xspeed = this.PRIVATE_GRAVITY_FORCE_FACTOR_X;
    }

    if (this.options.gravityAngleVariance !== 0) {
        drop.xspeed +=
            (Math.random() * 2 - 1) *
            drop.yspeed *
            this.options.gravityAngleVariance;
    }

    drop.y += Math.floor(drop.yspeed);
    drop.x += Math.floor(drop.xspeed);

    drop.draw();
    return false;
};

/**
 * Utility function to return positive min value
 * @param val1 first number
 * @param val2 second number
 */
RainyDay.prototype.positiveMin = function (value1, value2) {
    var result = 0;
    if (value1 < value2) {
        result = value1 <= 0 ? value2 : value1;
    } else {
        result = value2 <= 0 ? value1 : value2;
    }
    return result <= 0 ? 1 : result;
};

/**
 * REFLECTION function: no reflection at all
 */
RainyDay.prototype.REFLECTION_NONE = function () {
    this.context.fillStyle = this.options.fillStyle;
    this.context.fill();
};

/**
 * REFLECTION function: miniature reflection (default)
 * @param drop raindrop object
 */

RainyDay.prototype.REFLECTION_MINIATURE = function (drop) {
    var sx = Math.max(
        (drop.x - this.options.reflectionDropMappingWidth) /
        this.options.reflectionScaledownFactor,
        0,
    );
    var sy = Math.max(
        (drop.y - this.options.reflectionDropMappingHeight) /
        this.options.reflectionScaledownFactor,
        0,
    );

    var sw = this.positiveMin(
        (this.options.reflectionDropMappingWidth * 2) /
        this.options.reflectionScaledownFactor,
        this.reflected.width - sx,
    );
    var sh = this.positiveMin(
        (this.options.reflectionDropMappingHeight * 2) /
        this.options.reflectionScaledownFactor,
        this.reflected.height - sy,
    );
    var dx = Math.max(drop.x - 1.1 * drop.r, 0);
    var dy = Math.max(drop.y - 1.1 * drop.r, 0);
    this.context.drawImage(
        this.reflected,
        Math.floor(sx),
        Math.floor(sy),
        Math.floor(sw),
        Math.floor(sh),
        Math.floor(dx),
        Math.floor(dy),
        drop.r * 2,
        drop.r * 2,
    );
};

/**
 * COLLISION function: default collision implementation
 * @param drop one of the drops colliding
 * @param collisions list of potential collisions
 */
RainyDay.prototype.COLLISION_SIMPLE = function (drop, collisions) {
    var item = collisions;
    var drop2;
    while (item != undefined) {
        var p = item.drop;
        var radiusSum = drop.r + p.r;
        var dx = drop.x - p.x;
        var dy = drop.y - p.y;
        if (
            Math.abs(dx) < radiusSum &&
            Math.abs(dy) < radiusSum &&
            Math.sqrt(Math.pow(drop.x - p.x, 2) + Math.pow(drop.y - p.y, 2)) <
            drop.r + p.r
        ) {
            drop2 = p;
            break;
        }
        item = item.next;
    }

    if (!drop2) {
        return;
    }

    // rename so that we're dealing with low/high drops
    var higher, lower;
    if (drop.y > drop2.y) {
        higher = drop;
        lower = drop2;
    } else {
        higher = drop2;
        lower = drop;
    }

    this.clearDrop(lower);
    // force stopping the second drop
    this.clearDrop(higher, true);
    this.matrix.remove(higher);
    lower.draw();

    lower.colliding = higher;
    lower.collided = true;
};

/**
 * Resizes canvas, draws original image and applies blurring algorithm.
 */
RainyDay.prototype.prepareBackground = function () {
    this.background = document.createElement("canvas");
    this.background.width = this.canvas.width;
    this.background.height = this.canvas.height;

    this.clearbackground = document.createElement("canvas");
    this.clearbackground.width = this.canvas.width;
    this.clearbackground.height = this.canvas.height;

    var context = this.background.getContext("2d");
    // context.clearRect(0, 0, this.canvas.width, this.canvas.height);

    context.drawImage(
        this.img,
        this.options.crop[0],
        this.options.crop[1],
        this.options.crop[2],
        this.options.crop[3],
        0,
        0,
        this.canvas.width,
        this.canvas.height,
    );

    context = this.clearbackground.getContext("2d");
    // context.clearRect(0, 0, this.canvas.width, this.canvas.height);
    context.drawImage(
        this.img,
        this.options.crop[0],
        this.options.crop[1],
        this.options.crop[2],
        this.options.crop[3],
        0,
        0,
        this.canvas.width,
        this.canvas.height,
    );

    if (!isNaN(this.options.blur) && this.options.blur >= 1) {
        this.stackBlurCanvasRGB(
            this.canvas.width,
            this.canvas.height,
            this.options.blur,
        );
    }
};

/**
 * Implements the Stack Blur Algorithm (@see http://www.quasimondo.com/StackBlurForCanvas/StackBlurDemo.html).
 * @param width width of the canvas
 * @param height height of the canvas
 * @param radius blur radius
 */
RainyDay.prototype.stackBlurCanvasRGB = function (width, height, radius) {
    var shgTable = [
        [0, 9],
        [1, 11],
        [2, 12],
        [3, 13],
        [5, 14],
        [7, 15],
        [11, 16],
        [15, 17],
        [22, 18],
        [31, 19],
        [45, 20],
        [63, 21],
        [90, 22],
        [127, 23],
        [181, 24],
    ];

    var mulTable = [
        512, 512, 456, 512, 328, 456, 335, 512, 405, 328, 271, 456, 388, 335,
        292, 512, 454, 405, 364, 328, 298, 271, 496, 456, 420, 388, 360, 335,
        312, 292, 273, 512, 482, 454, 428, 405, 383, 364, 345, 328, 312, 298,
        284, 271, 259, 496, 475, 456, 437, 420, 404, 388, 374, 360, 347, 335,
        323, 312, 302, 292, 282, 273, 265, 512, 497, 482, 468, 454, 441, 428,
        417, 405, 394, 383, 373, 364, 354, 345, 337, 328, 320, 312, 305, 298,
        291, 284, 278, 271, 265, 259, 507, 496, 485, 475, 465, 456, 446, 437,
        428, 420, 412, 404, 396, 388, 381, 374, 367, 360, 354, 347, 341, 335,
        329, 323, 318, 312, 307, 302, 297, 292, 287, 282, 278, 273, 269, 265,
        261, 512, 505, 497, 489, 482, 475, 468, 461, 454, 447, 441, 435, 428,
        422, 417, 411, 405, 400, 396, 392, 388, 385, 381, 377, 374, 370, 367,
        363, 360, 357, 354, 350, 347, 344, 341, 338, 335, 332, 329, 326, 323,
        320, 318, 315, 312, 310, 307, 304, 302, 299, 297, 294, 292, 289, 287,
        285, 282, 280, 278, 275, 273, 271, 269, 267, 265, 263, 261, 259,
    ];

    radius = Math.trunc(radius);

    var context = this.background.getContext("2d");
    var imageData = context.getImageData(0, 0, width, height);
    var pixels = imageData.data;
    var x,
        y,
        index,
        p,
        yp,
        yi,
        yw,
        rSum,
        gSum,
        bSum,
        rOutSum,
        gOutSum,
        bOutSum,
        rInSum,
        gInSum,
        bInSum,
        pr,
        pg,
        pb,
        rbs;
    var radiusPlus1 = radius + 1;
    var sumFactor = (radiusPlus1 * (radiusPlus1 + 1)) / 2;

    var stackStart = new BlurStack();
    var stackEnd = new BlurStack();
    var stack = stackStart;
    for (index = 1; index < 2 * radius + 1; index++) {
        stack = stack.next = new BlurStack();
        if (index === radiusPlus1) {
            stackEnd = stack;
        }
    }
    stack.next = stackStart;
    var stackIn = null;
    var stackOut = null;

    yw = yi = 0;

    var mulSum = mulTable[radius];
    var shgSum;
    for (var ssi = 0; ssi < shgTable.length; ++ssi) {
        if (radius <= shgTable[ssi][0]) {
            shgSum = shgTable[ssi - 1][1];
            break;
        }
    }

    for (y = 0; y < height; y++) {
        rInSum = gInSum = bInSum = rSum = gSum = bSum = 0;

        rOutSum = radiusPlus1 * (pr = pixels[yi]);
        gOutSum = radiusPlus1 * (pg = pixels[yi + 1]);
        bOutSum = radiusPlus1 * (pb = pixels[yi + 2]);

        rSum += sumFactor * pr;
        gSum += sumFactor * pg;
        bSum += sumFactor * pb;

        stack = stackStart;

        for (index = 0; index < radiusPlus1; index++) {
            stack.r = pr;
            stack.g = pg;
            stack.b = pb;
            stack = stack.next;
        }

        for (index = 1; index < radiusPlus1; index++) {
            p = yi + (Math.min(width - 1, index) << 2);
            rSum += (stack.r = pr = pixels[p]) * (rbs = radiusPlus1 - index);
            gSum += (stack.g = pg = pixels[p + 1]) * rbs;
            bSum += (stack.b = pb = pixels[p + 2]) * rbs;

            rInSum += pr;
            gInSum += pg;
            bInSum += pb;

            stack = stack.next;
        }

        stackIn = stackStart;
        stackOut = stackEnd;
        for (x = 0; x < width; x++) {
            pixels[yi] = (rSum * mulSum) >> shgSum;
            pixels[yi + 1] = (gSum * mulSum) >> shgSum;
            pixels[yi + 2] = (bSum * mulSum) >> shgSum;

            rSum -= rOutSum;
            gSum -= gOutSum;
            bSum -= bOutSum;

            rOutSum -= stackIn.r;
            gOutSum -= stackIn.g;
            bOutSum -= stackIn.b;

            p = (yw + ((p = x + radius + 1) < width - 1 ? p : width - 1)) << 2;

            rInSum += stackIn.r = pixels[p];
            gInSum += stackIn.g = pixels[p + 1];
            bInSum += stackIn.b = pixels[p + 2];

            rSum += rInSum;
            gSum += gInSum;
            bSum += bInSum;

            stackIn = stackIn.next;

            rOutSum += pr = stackOut.r;
            gOutSum += pg = stackOut.g;
            bOutSum += pb = stackOut.b;

            rInSum -= pr;
            gInSum -= pg;
            bInSum -= pb;

            stackOut = stackOut.next;

            yi += 4;
        }
        yw += width;
    }

    for (x = 0; x < width; x++) {
        gInSum = bInSum = rInSum = gSum = bSum = rSum = 0;

        yi = x << 2;
        rOutSum = radiusPlus1 * (pr = pixels[yi]);
        gOutSum = radiusPlus1 * (pg = pixels[yi + 1]);
        bOutSum = radiusPlus1 * (pb = pixels[yi + 2]);

        rSum += sumFactor * pr;
        gSum += sumFactor * pg;
        bSum += sumFactor * pb;

        stack = stackStart;

        for (index = 0; index < radiusPlus1; index++) {
            stack.r = pr;
            stack.g = pg;
            stack.b = pb;
            stack = stack.next;
        }

        yp = width;

        for (index = 1; index < radiusPlus1; index++) {
            yi = (yp + x) << 2;

            rSum += (stack.r = pr = pixels[yi]) * (rbs = radiusPlus1 - index);
            gSum += (stack.g = pg = pixels[yi + 1]) * rbs;
            bSum += (stack.b = pb = pixels[yi + 2]) * rbs;

            rInSum += pr;
            gInSum += pg;
            bInSum += pb;

            stack = stack.next;

            if (index < height - 1) {
                yp += width;
            }
        }

        yi = x;
        stackIn = stackStart;
        stackOut = stackEnd;
        for (y = 0; y < height; y++) {
            p = yi << 2;
            pixels[p] = (rSum * mulSum) >> shgSum;
            pixels[p + 1] = (gSum * mulSum) >> shgSum;
            pixels[p + 2] = (bSum * mulSum) >> shgSum;

            rSum -= rOutSum;
            gSum -= gOutSum;
            bSum -= bOutSum;

            rOutSum -= stackIn.r;
            gOutSum -= stackIn.g;
            bOutSum -= stackIn.b;

            p =
                (x +
                    ((p = y + radiusPlus1) < height - 1 ? p : height - 1) *
                    width) <<
                2;

            rSum += rInSum += stackIn.r = pixels[p];
            gSum += gInSum += stackIn.g = pixels[p + 1];
            bSum += bInSum += stackIn.b = pixels[p + 2];

            stackIn = stackIn.next;

            rOutSum += pr = stackOut.r;
            gOutSum += pg = stackOut.g;
            bOutSum += pb = stackOut.b;

            rInSum -= pr;
            gInSum -= pg;
            bInSum -= pb;

            stackOut = stackOut.next;

            yi += width;
        }
    }

    context.putImageData(imageData, 0, 0);
};

/**
 * Defines a new helper object for Stack Blur Algorithm.
 */
function BlurStack() {
    this.r = 0;
    this.g = 0;
    this.b = 0;
    this.next = null;
}

/**
 * Defines a gravity matrix object which handles collision detection.
 * @param x number of columns in the matrix
 * @param y number of rows in the matrix
 * @param r grid size
 */
function CollisionMatrix(x, y, r) {
    this.resolution = r;
    this.xc = x;
    this.yc = y;
    this.matrix = new Array(x);
    for (var index = 0; index <= x + 5; index++) {
        this.matrix[index] = new Array(y);
        for (var index_ = 0; index_ <= y + 5; ++index_) {
            this.matrix[index][index_] = new DropItem(null);
        }
    }
}

/**
 * Updates position of the given drop on the collision matrix.
 * @param drop raindrop to be positioned/repositioned
 * @param forceDelete if true the raindrop will be removed from the matrix
 * @returns collisions if any
 */
CollisionMatrix.prototype.update = function (drop, forceDelete) {
    if (drop.gid) {
        if (!this.matrix[drop.gmx] || !this.matrix[drop.gmx][drop.gmy]) {
            return null;
        }
        this.matrix[drop.gmx][drop.gmy].remove(drop);
        if (forceDelete) {
            return null;
        }

        drop.gmx = Math.floor(drop.x / this.resolution);
        drop.gmy = Math.floor(drop.y / this.resolution);
        if (!this.matrix[drop.gmx] || !this.matrix[drop.gmx][drop.gmy]) {
            return null;
        }
        this.matrix[drop.gmx][drop.gmy].add(drop);

        var collisions = this.collisions(drop);
        if (collisions && collisions.next != undefined) {
            return collisions.next;
        }
    } else {
        drop.gid = Math.random().toString(36).slice(2, 11);
        drop.gmx = Math.floor(drop.x / this.resolution);
        drop.gmy = Math.floor(drop.y / this.resolution);
        if (!this.matrix[drop.gmx] || !this.matrix[drop.gmx][drop.gmy]) {
            return null;
        }

        this.matrix[drop.gmx][drop.gmy].add(drop);
    }
    return null;
};

/**
 * Looks for collisions with the given raindrop.
 * @param drop raindrop to be checked
 * @returns DropItem list of drops that collide with it
 */
CollisionMatrix.prototype.collisions = function (drop) {
    var item = new DropItem(null);
    var first = item;

    item = this.addAll(item, drop.gmx - 1, drop.gmy + 1);
    item = this.addAll(item, drop.gmx, drop.gmy + 1);
    item = this.addAll(item, drop.gmx + 1, drop.gmy + 1);

    return first;
};

/**
 * Appends all found drop at a given location to the given item.
 * @param to item to which the results will be appended to
 * @param x x position in the matrix
 * @param y y position in the matrix
 * @returns last discovered item on the list
 */
CollisionMatrix.prototype.addAll = function (to, x, y) {
    if (x > 0 && y > 0 && x < this.xc && y < this.yc) {
        var items = this.matrix[x][y];
        while (items.next != undefined) {
            items = items.next;
            to.next = new DropItem(items.drop);
            to = to.next;
        }
    }
    return to;
};

/**
 * Removed the drop from its current position
 * @param drop to be removed
 */
CollisionMatrix.prototype.remove = function (drop) {
    this.matrix[drop.gmx][drop.gmy].remove(drop);
};

/**
 * Defines a linked list item.
 */
function DropItem(drop) {
    this.drop = drop;
    this.next = null;
}

/**
 * Adds the raindrop to the end of the list.
 * @param drop raindrop to be added
 */
DropItem.prototype.add = function (drop) {
    var item = this;
    while (item.next != undefined) {
        item = item.next;
    }
    item.next = new DropItem(drop);
};

/**
 * Removes the raindrop from the list.
 * @param drop raindrop to be removed
 */
DropItem.prototype.remove = function (drop) {
    var item = this;
    var previousItem = null;
    while (item.next != undefined) {
        previousItem = item;
        item = item.next;
        if (item.drop.gid === drop.gid) {
            previousItem.next = item.next;
        }
    }
};

/**
 * Jquery getOffset method
 */
globalThis.getOffset = function (element) {
    // Preserve chaining for setter
    if (typeof element === "string") {
        element = document.getElementById(element);
    }

    var document_,
        documentElement,
        rect,
        win,
        element_ = element;

    if (!element_) {
        return;
    }

    // Return zeros for disconnected and hidden (display: none) elements (gh-2310)
    // Support: IE <=11 only
    // Running getBoundingClientRect on a
    // disconnected node in IE throws an error
    if (element_.getClientRects().length === 0) {
        return {
            top: 0,
            left: 0,
        };
    }

    rect = element_.getBoundingClientRect();

    document_ = element_.ownerDocument;
    documentElement = document_.documentElement;
    win = document_.defaultView;

    return {
        top: rect.top + win.pageYOffset - documentElement.clientTop,
        left: rect.left + win.pageXOffset - documentElement.clientLeft,
    };
};

/**
 * Image downscale
 */
function downscaleImage(img, width) {
    var cv = document.createElement("canvas");
    var context = cv.getContext("2d");
    cv.width = width || 50;
    cv.height = (cv.width * img.height) / img.width;
    context.drawImage(
        img,
        0,
        0,
        img.width,
        img.height,
        0,
        0,
        cv.width,
        cv.height,
    );
    return cv;
}

/**
 * Play sound loop
 */

function playSound(url) {
    var audio = new Audio(url);
    audio.loop = true;
    audio.volume = 0.25;
    audio.play();
    return audio;
}

globalThis.RainyDay = RainyDay;
