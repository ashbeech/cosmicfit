//
//  MotionSheenView.swift
//  Cosmic Fit
//
//  Iridescent holographic sheen overlay that responds to device motion
//  (gyroscope + accelerometer fused via Core Motion `deviceMotion`).
//
//  Physical model
//  --------------
//  A real holographic foil card has fixed microscopic grooves baked into
//  the material. The grooves do NOT rotate when you tilt the card —
//  what changes is the angle between the surface normal and the light
//  source, and therefore the wavelength that interferes constructively
//  at each point. Visually, that reads as: the rainbow band stays in
//  roughly the same orientation, but the *colour at any given pixel*
//  cycles through the spectrum as you tilt.
//
//  Implementation
//  --------------
//  • A single `CAGradientLayer` carries the iridescent rainbow with the
//    full spectrum looped twice so we always see a full hue range across
//    the card. Tilt phase-shifts the colour stops — the gradient
//    direction itself only swings gently — so the rainbow never
//    compresses into thin bands and we never get an "X" from crossed
//    layers.
//  • A single soft specular highlight band sweeps across the card with
//    tilt, simulating a fixed light source above the device.
//  • Both are blended over the card art at low opacity so the artwork
//    remains the dominant element, with the foil shimmer reading as a
//    subtle *property* of the card rather than a layer painted on top.
//
//  Constraints (per product spec)
//  ------------------------------
//  • Sheen must perfectly match the visible card — no bleed past the
//    card edge. Achieved by masking the layer with the card image's
//    alpha channel using `CALayer.contentsGravity = .resizeAspect`.
//  • No idle/timer-driven animation. Layer state updates ONLY when a
//    new motion sample arrives. On a device/simulator without a gyro,
//    the sheen renders at neutral (no fake animation).
//  • Sheen must be present from the moment the card image is visible.
//    Set `cardImage` in the same synchronous beat you assign the host
//    `UIImageView.image` so they appear together on the next paint.
//

import UIKit
import CoreMotion
import QuartzCore
import simd

/// An iridescent, motion-reactive sheen overlay sized and masked to
/// match the alpha of a host card image (front or back).
///
/// Add as a subview of the `UIImageView` that hosts the card art and
/// pin its edges to the imageView's bounds. The mask uses
/// `contentsGravity = .resizeAspect`, which letterboxes the card image
/// in exactly the same way `UIImageView.contentMode = .scaleAspectFit`
/// does — so the sheen mask aligns 1:1 with the rendered card pixels
/// and never bleeds past the visible card edge (rounded corners and any
/// transparent regions in the artwork are honoured automatically).
final class MotionSheenView: UIView {

    // MARK: - Public API

    /// The card image whose alpha defines the visible card outline.
    /// Setting this updates the mask and toggles visibility. Pass `nil`
    /// to hide the sheen.
    var cardImage: UIImage? {
        didSet {
            updateMaskAndLayout()
            isHidden = (cardImage == nil)
        }
    }

    /// Overall sheen intensity multiplier (0…1). Defaults to `1.0`.
    var intensity: CGFloat = 1.0 {
        didSet {
            intensity = max(0, min(1, intensity))
            applyIntensity()
        }
    }

    // MARK: - Layers

    /// The iridescent rainbow tint. Direction is roughly fixed; tilt
    /// phase-shifts the colour stops (see `applyTilt`).
    private let irisLayer = CAGradientLayer()
    /// A soft white specular streak that slides across the card with
    /// tilt, simulating a fixed light source above the device.
    private let highlightLayer = CAGradientLayer()
    /// Alpha mask cut from the card image so the sheen never bleeds
    /// past the visible card outline.
    private let imageMaskLayer = CALayer()

    // MARK: - Tunables
    //
    // The defaults here have been calibrated against frames from a
    // physical iPhone so the sheen reads as a *property* of the card
    // rather than as paint applied on top. Adjust with care.

    /// Base opacity of the rainbow tint when intensity = 1. Low enough
    /// that the underlying card art remains the dominant visual.
    private static let irisBaseOpacity: Float = 0.33 * (2.0 / 3.0)
    /// Base opacity of the specular highlight when intensity = 1.
    private static let highlightBaseOpacity: Float = 0.22 * (2.0 / 3.0)

    /// Total radians of phase rotation as the device tilts edge-to-edge.
    /// One rainbow loop = 2π; we move through ~1.6 loops between
    /// extreme tilts so the user clearly sees colours cycling but never
    /// in a way that feels gimmicky.
    private static let phaseSweepRadians: Double = .pi * 3.2

    /// Half-length of the gradient axis as a fraction of the card. Kept
    /// at exactly 0.5 so the gradient endpoints sit on the unit square
    /// (corner to corner) regardless of tilt — this is what guarantees
    /// the rainbow always spans the entire card with the full spectrum
    /// visible, instead of crowding into a thin slice at extreme tilts.
    private static let irisHalfReach: CGFloat = 0.5

    /// How far the centre of the specular highlight slides as the
    /// device tilts edge-to-edge, in unit-square coordinates.
    private static let highlightSlideRange: CGFloat = 0.42

    /// Vertical position of the specular highlight at zero tilt, in
    /// unit-square coordinates (`0.5` = card centre, larger = lower).
    /// Tuned so the bright pool sits in the upper third of the card
    /// at rest — this gives a rich starting reflection that's still
    /// visible when the device is held flat, while leaving room above
    /// and below for the highlight to slide into as the user tilts.
    private static let highlightRestY: CGFloat = 0.62 - (1.0 / 3.33)

    /// Half-width of the specular highlight band. Wider = softer pool,
    /// narrower = crisper streak. Tuned to never clip below this.
    private static let highlightHalfWidth: CGFloat = 0.45

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        isUserInteractionEnabled = false
        clipsToBounds = true
        // Sheen stays at this composition until a motion sample arrives
        // (no fake animation on idle/simulator).
        isHidden = true

        // Iridescence: 15 colour stops covering 1.5 rainbow loops at
        // uniform spacing. Phase shift in `applyTilt` rotates the colour
        // *content* through these fixed positions, so a given pixel
        // smoothly cycles through hues without the gradient direction
        // having to translate or compress.
        irisLayer.type = .axial
        irisLayer.colors = MotionSheenView.iridescentColors(phaseRadians: 0)
        irisLayer.locations = MotionSheenView.iridescentLocations
        // `multiply` darkens the card art underneath — reads as reflected
        // light on foil rather than a tint painted on top.
        irisLayer.compositingFilter = "colorDodgeBlendMode"
        irisLayer.opacity = MotionSheenView.irisBaseOpacity
        layer.addSublayer(irisLayer)

        // Specular highlight: a soft white band, narrower stops and
        // more gradual falloff than before so it reads as a pool of
        // light rather than a stripe.
        highlightLayer.type = .axial
        highlightLayer.colors = [
            UIColor.white.withAlphaComponent(0.0).cgColor,
            UIColor.white.withAlphaComponent(0.55).cgColor,
            UIColor.white.withAlphaComponent(0.95).cgColor,
            UIColor.white.withAlphaComponent(0.55).cgColor,
            UIColor.white.withAlphaComponent(0.0).cgColor
        ]
        highlightLayer.locations = [0.0, 0.30, 0.50, 0.70, 1.0]
        highlightLayer.compositingFilter = "screenBlendMode"
        highlightLayer.opacity = MotionSheenView.highlightBaseOpacity
        layer.addSublayer(highlightLayer)

        // `.resizeAspect` mirrors `UIImageView.contentMode = .scaleAspectFit`,
        // letterboxing the mask image inside the layer with transparent
        // padding. Transparent mask alpha = invisible content, which is
        // exactly what keeps the sheen flush with the visible card edge.
        imageMaskLayer.contentsGravity = .resizeAspect
        layer.mask = imageMaskLayer

        // Apply neutral tilt so first paint is a coherent state, not
        // whatever the gradient defaults happened to be.
        applyTilt(x: 0, y: 0)
    }

    // MARK: - Lifecycle

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            // Only subscribe once we have a card image AND a window —
            // no point burning the gyro for an off-screen sheen.
            if cardImage != nil {
                MotionSheenDriver.shared.subscribe(self)
            }
        } else {
            MotionSheenDriver.shared.unsubscribe(self)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateMaskAndLayout()
    }

    deinit {
        MotionSheenDriver.shared.unsubscribe(self)
    }

    // MARK: - Layout / mask

    /// Keeps every sublayer frame and the mask contents in sync with
    /// the current view bounds. Implicit animations are disabled so a
    /// fresh card image and its sheen always paint together (no
    /// perceptible delay between the card art appearing and the sheen
    /// snapping into place — that asymmetry would break the illusion of
    /// the sheen being part of the physical card).
    private func updateMaskAndLayout() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let layerBounds = bounds
        irisLayer.frame = layerBounds
        highlightLayer.frame = layerBounds
        imageMaskLayer.frame = layerBounds
        imageMaskLayer.contents = cardImage?.cgImage

        CATransaction.commit()
    }

    private func applyIntensity() {
        let i = Float(intensity)
        irisLayer.opacity = MotionSheenView.irisBaseOpacity * i
        highlightLayer.opacity = MotionSheenView.highlightBaseOpacity * i
    }

    // MARK: - Motion application

    /// Applies a smoothed tilt vector (units: radians from calibrated
    /// neutral). Called from `MotionSheenDriver` on the main queue.
    fileprivate func applyTilt(x: Double, y: Double) {
        // Tilt expressed in "edge-to-edge" units, where ±1 corresponds
        // to roughly ±33° of tilt (since the gravity in-plane
        // component changes by `sin(angle)`, so 0.55 ≈ sin(33°)).
        // Two flavours:
        //   • `txRaw` / `tyRaw`: unclamped. Used for the iris phase
        //     shift, which is naturally cyclic — letting the value
        //     keep growing past ±1 means the colour cycle keeps
        //     advancing as the user rotates the device through 90°,
        //     180° and beyond, instead of freezing at the saturation
        //     point. The hue calculation already does
        //     `truncatingRemainder(dividingBy: 1.0)` so the loop is
        //     seamless across any rotation.
        //   • `tx` / `ty`: clamped to `[-1, 1]`. Used only for the
        //     specular highlight position, so the bright pool stays
        //     on the card at extreme tilts instead of flying off the
        //     edge (which would break the illusion of light bouncing
        //     off the card surface).
        let tiltMax = 0.55
        let txRaw = x / tiltMax
        let tyRaw = y / tiltMax
        let tx = max(-1.0, min(1.0, txRaw))
        let ty = max(-1.0, min(1.0, tyRaw))

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // ── Iridescence ──────────────────────────────────────────
        //
        // The gradient direction is FIXED at 135° (top-right → bottom-
        // left). Tilt does not rotate the axis at all — it only
        // phase-shifts the colour stops along it. This is critical for
        // seamless motion: deriving an angle from `(tx, ty)` (e.g. via
        // `atan2`) introduces two discontinuities that read as visible
        // jumps:
        //   1. `atan2` is undefined at the origin, so when the device
        //      is near-flat, gyroscope noise jitters the angle through
        //      arbitrary values.
        //   2. `atan2` wraps from +π to -π when the tilt direction
        //      sweeps past "left", causing a snap on circular sweeps.
        // Keeping the axis fixed eliminates both.
        //
        // The phase shift below is a smooth scalar function of (tx, ty)
        // — the dot product of tilt with the gradient's perpendicular —
        // so colours cycle continuously across every tilt direction.
        // Tilting *across* the rainbow cycles colours; tilting *along*
        // it does nothing, which mirrors how a real foil reads.
        let baseAngle: Double = 3 * .pi / 4
        let cosI = CGFloat(cos(baseAngle))
        let sinI = CGFloat(sin(baseAngle))
        let r = MotionSheenView.irisHalfReach
        irisLayer.startPoint = CGPoint(x: 0.5 - r * cosI, y: 0.5 - r * sinI)
        irisLayer.endPoint   = CGPoint(x: 0.5 + r * cosI, y: 0.5 + r * sinI)

        // Phase drive uses the *unclamped* tilt vector dotted with the
        // gradient perpendicular. Continuing past ±1 lets the colour
        // cycle keep advancing through full device rotations, looping
        // seamlessly via the modulo-1 hue wrap inside
        // `iridescentColors(phaseRadians:)`.
        let perpX = -sin(baseAngle)
        let perpY =  cos(baseAngle)
        let phaseDrive = txRaw * perpX + tyRaw * perpY
        let phaseRadians = phaseDrive * MotionSheenView.phaseSweepRadians
        irisLayer.colors = MotionSheenView.iridescentColors(phaseRadians: phaseRadians)

        // ── Specular highlight ──────────────────────────────────
        //
        // Treat the device as if a virtual light hovered above it. The
        // highlight band's *orientation* is fixed perpendicular to the
        // iris axis — same reasoning as above, using `atan2(ty, tx)`
        // here was the source of the visible "jump" when transitioning
        // from flat to tilted, and again when crossing from one tilt
        // direction to another. Only the *centre* of the band slides,
        // and that slide is a smooth linear function of (tx, ty).
        let hlSlide = MotionSheenView.highlightSlideRange
        let hlCx: CGFloat = 0.5 - CGFloat(tx) * hlSlide
        let hlCy: CGFloat = MotionSheenView.highlightRestY - CGFloat(ty) * hlSlide

        let hlAngle = baseAngle + .pi / 2
        let hlW = MotionSheenView.highlightHalfWidth
        let cosH = CGFloat(cos(hlAngle))
        let sinH = CGFloat(sin(hlAngle))
        highlightLayer.startPoint = CGPoint(x: hlCx - hlW * cosH, y: hlCy - hlW * sinH)
        highlightLayer.endPoint   = CGPoint(x: hlCx + hlW * cosH, y: hlCy + hlW * sinH)

        CATransaction.commit()
    }

    // MARK: - Iridescent palette

    /// Uniform 0…1 locations across `iridescentColors` so phase shifts
    /// translate cleanly to colour-stop rotation.
    private static let iridescentLocations: [NSNumber] = {
        let n = MotionSheenView.iridescentStopCount
        return (0..<n).map { NSNumber(value: Double($0) / Double(n - 1)) }
    }()

    /// 15 colour stops works out to a smooth rainbow without visible
    /// banding on iPhone displays.
    private static let iridescentStopCount = 15

    /// Builds the colour array for a given phase offset (radians).
    ///
    /// The visible gradient covers exactly one rainbow loop; we
    /// pre-stretch it across `loopCount` cycles so neighbouring stops
    /// are always close in hue (avoids visible "rainbow seam" lines).
    /// Saturation/brightness are tuned to look correct under a
    /// `screen` blend — fully saturated colours at this opacity
    /// would overwhelm the card art.
    private static func iridescentColors(phaseRadians: Double) -> [CGColor] {
        let n = iridescentStopCount
        let loopCount: Double = 1.25
        let phaseTurns = phaseRadians / (2 * .pi)
        var result: [CGColor] = []
        result.reserveCapacity(n)
        for i in 0..<n {
            let position = Double(i) / Double(n - 1)
            var hue = position * loopCount + phaseTurns
            hue = hue.truncatingRemainder(dividingBy: 1.0)
            if hue < 0 { hue += 1.0 }
            // Saturation 0.55 + brightness 1.0 + screen blend reads
            // as a rich tint without painting over the card. Increase
            // saturation here only if you also drop `irisBaseOpacity`.
            let colour = UIColor(
                hue: CGFloat(hue),
                saturation: 1.0,
                brightness: 0.5,
                alpha: 0.2
            )
            result.append(colour.cgColor)
        }
        return result
    }
}

// MARK: - Motion-driven card parallax

/// Subtly counter-rotates a host view in 3D in response to device motion,
/// giving the impression that the host is a physical object held in space
/// rather than a flat region of the screen — like an Apple Pay card that
/// "floats" above the wallet, leaning against the user's tilt.
///
/// Pair with `MotionSheenView` so the iridescent sheen and the parallax
/// share a single calibrated baseline and the same gimbal-lock-free
/// motion source. Designed to be safe to use on the same view that runs
/// the back→front 3D flip animation: the flip operates on the inner
/// image views' `layer.transform` and on the host's `sublayerTransform`,
/// while parallax writes to the host's own `layer.transform` — different
/// properties, so they compose cleanly without overwriting each other.
///
/// Usage:
/// ```
/// // Hold a strong reference for the lifetime you want parallax active.
/// parallax = MotionParallaxBinding(host: cardContainer)
/// // Drop the reference (or set to nil) to stop and reset to identity.
/// parallax = nil
/// ```
public final class MotionParallaxBinding {

    fileprivate weak var hostView: UIView?

    /// Maximum rotation magnitude (radians) reached at extreme tilts.
    /// `tanh` easing means the rotation grows linearly near zero and
    /// asymptotes smoothly into this clamp at the extremes — the user
    /// never sees a hard cap, just the parallax slowing as it nears
    /// the saturation point. Default ~3.7°: gentle and understated.
    public var maxAngleRadians: Double = 0.065

    /// How aggressively `tanh` saturates. Larger values reach near-clamp
    /// rotation with smaller device tilts. Tuned so the bulk of the
    /// motion happens within natural hand-held tilt ranges.
    public var inputGain: Double = 1.6

    /// Camera-plane distance for the perspective transform. Smaller =
    /// more pronounced 3D foreshortening. Set high enough that the
    /// effect reads as subtle depth rather than a billboard pivot.
    public var perspectiveDistance: Double = 900

    /// Additional transform applied beneath the parallax rotation.
    /// Use this when another system needs to write to the host's
    /// `layer.transform` (most commonly a scroll-driven parallax
    /// translation): instead of letting the two writers race and
    /// overwrite each other on alternating frames — which reads as a
    /// scroll-time jitter — the caller pushes its transform through
    /// here and the binding composes it with the parallax rotation
    /// every tick. Always written and read on the main thread.
    public var hostBaseTransform: CATransform3D = CATransform3DIdentity {
        didSet {
            // Re-render with the most recent tilt so callers don't
            // have to wait for the next motion sample to see the
            // new base transform reflected on screen.
            applyComposedTransform()
        }
    }

    /// Latest tilt vector delivered by `MotionSheenDriver`. Cached so
    /// `applyComposedTransform` can rebuild the layer transform when
    /// `hostBaseTransform` changes between motion ticks.
    private var lastTiltX: Double = 0
    private var lastTiltY: Double = 0

    public init(host: UIView) {
        self.hostView = host
        MotionSheenDriver.shared.subscribe(self)
    }

    deinit {
        MotionSheenDriver.shared.unsubscribe(self)
        // Restore identity transform so the host doesn't keep a stale
        // parallax tilt baked in after the binding goes away.
        hostView?.layer.transform = CATransform3DIdentity
    }

    fileprivate func applyTilt(x: Double, y: Double) {
        lastTiltX = x
        lastTiltY = y
        applyComposedTransform()
    }

    private func applyComposedTransform() {
        guard let host = hostView else { return }

        // `tanh` produces a smooth, monotonic mapping from any real
        // input to (-1, 1) — linear near zero, asymptotic at the
        // extremes. That's exactly the easing we want: full
        // responsiveness for normal tilts, gentle slowing near the
        // clamps so the parallax never feels like it hits a wall.
        let easedX = tanh(lastTiltX * inputGain)
        let easedY = tanh(lastTiltY * inputGain)

        // Inverted: device tilt one way, card leans the opposite way,
        // simulating an object that's anchored in space relative to
        // the user's eye while the device frame moves around it.
        let angleX = -easedY * maxAngleRadians
        let angleY = -easedX * maxAngleRadians

        // Bake perspective into the rotation matrix so a 3D rotation
        // reads as actual depth rather than a flat affine squash. We
        // deliberately do NOT touch the host's `sublayerTransform`:
        // the card flip animation owns that, and splitting these two
        // properties between parallax and flip is what lets them
        // coexist without fighting.
        var rotation = CATransform3DIdentity
        rotation.m34 = -1.0 / CGFloat(perspectiveDistance)
        rotation = CATransform3DRotate(rotation, CGFloat(angleX), 1, 0, 0)
        rotation = CATransform3DRotate(rotation, CGFloat(angleY), 0, 1, 0)

        // Compose: rotation applied first (in the layer's local
        // space), then the caller's base transform (e.g. a scroll
        // translation in screen space) on top. `Concat(a, b) = a · b`
        // in column-vector convention, so this means "apply rotation,
        // then base".
        let composed = CATransform3DConcat(rotation, hostBaseTransform)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        host.layer.transform = composed
        CATransaction.commit()
    }
}

// MARK: - Shared CoreMotion driver

/// Single shared motion source that fans out smoothed tilt samples to
/// any active `MotionSheenView` and `MotionParallaxBinding`. Subscribers
/// are held weakly; when the last subscriber is gone, motion updates
/// are fully stopped so we are not draining the gyro/accelerometer in
/// the background.
private final class MotionSheenDriver {

    static let shared = MotionSheenDriver()

    private let manager = CMMotionManager()
    private let subscribers = NSHashTable<MotionSheenView>.weakObjects()
    private let parallaxSubscribers = NSHashTable<MotionParallaxBinding>.weakObjects()

    /// Calibrated baseline of the device attitude, expressed as the
    /// rotation matrix from body frame to the (arbitrary, but fixed)
    /// reference frame Core Motion picked at the start of updates.
    ///
    /// We compute the apparent direction of a fixed virtual *light
    /// source* (`lightBaselineBody`) by comparing the current attitude
    /// to this baseline and projecting the result onto the screen
    /// plane. Two reasons this beats simpler approaches:
    ///
    /// 1. Rotation matrices have no gimbal lock, unlike Euler
    ///    `attitude.pitch` / `attitude.roll`, which go degenerate when
    ///    the device is held vertical and made the sheen "break".
    ///
    /// 2. Tracking gravity components alone (as we did before) only
    ///    captures pitch and roll — gravity is rotationally symmetric
    ///    about its own axis, so yawing a vertical device produces no
    ///    signal at all and the sheen would freeze. The matrix /
    ///    light-projection approach captures pitch, roll AND yaw in
    ///    every orientation, so rotating the phone left or right while
    ///    holding it upright moves the sheen smoothly the way it does
    ///    when the phone is held flat.
    private var baselineMatrix = matrix_identity_double3x3
    private var hasBaseline = false

    /// Virtual light direction expressed in the **baseline** body
    /// frame. Has both an in-plane (Y) and an out-of-plane (Z)
    /// component so all three rotation axes contribute to in-plane
    /// motion: the in-plane component picks up roll and pitch directly,
    /// the out-of-plane component creates a yaw-driven swing because
    /// rotating the body around its Z axis sweeps a Z-pointing vector
    /// across the X/Y plane.
    private static let lightBaselineBody = SIMD3<Double>(0, 0.5, 1.0)

    /// Smoothed tilt deltas (in-plane components of the projected
    /// virtual light direction) actually delivered to subscribers.
    private var smoothedX: Double = 0
    private var smoothedY: Double = 0

    private init() {}

    func subscribe(_ view: MotionSheenView) {
        if !subscribers.contains(view) {
            subscribers.add(view)
        }
        // Push the most recent smoothed tilt immediately so a freshly
        // attached sheen does not flash through neutral on first frame.
        view.applyTilt(x: smoothedX, y: smoothedY)
        startIfNeeded()
    }

    func unsubscribe(_ view: MotionSheenView) {
        subscribers.remove(view)
        stopIfNoSubscribers()
    }

    func subscribe(_ binding: MotionParallaxBinding) {
        if !parallaxSubscribers.contains(binding) {
            parallaxSubscribers.add(binding)
        }
        // Push the most recent smoothed tilt immediately so the host
        // view starts at the correct parallax angle on first frame
        // (avoids a one-frame snap from identity).
        binding.applyTilt(x: smoothedX, y: smoothedY)
        startIfNeeded()
    }

    func unsubscribe(_ binding: MotionParallaxBinding) {
        parallaxSubscribers.remove(binding)
        stopIfNoSubscribers()
    }

    private func stopIfNoSubscribers() {
        if subscribers.allObjects.isEmpty && parallaxSubscribers.allObjects.isEmpty {
            stop()
        }
    }

    private func startIfNeeded() {
        guard !manager.isDeviceMotionActive else { return }
        guard manager.isDeviceMotionAvailable else {
            // No gyro (e.g. simulator). We deliberately do NOT animate
            // anything in this case — the sheen simply stays at neutral.
            return
        }

        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            self.process(motion: motion)
        }
    }

    private func stop() {
        if manager.isDeviceMotionActive {
            manager.stopDeviceMotionUpdates()
        }
        hasBaseline = false
        smoothedX = 0
        smoothedY = 0
    }

    private func process(motion: CMDeviceMotion) {
        // Pull the body→reference rotation matrix into a SIMD type so
        // we can do clean matrix math.
        let m = motion.attitude.rotationMatrix
        let R = simd_double3x3(rows: [
            SIMD3(m.m11, m.m12, m.m13),
            SIMD3(m.m21, m.m22, m.m23),
            SIMD3(m.m31, m.m32, m.m33)
        ])

        if !hasBaseline {
            baselineMatrix = R
            hasBaseline = true
        }

        // Where does a vector that was fixed in the *baseline body*
        // frame appear in the *current body* frame? Take it to the
        // reference frame via R0 (baseline body→ref), then back into
        // the current body via R^T (ref→current body).
        let bodyToBody = R.transpose * baselineMatrix
        let lightCurrent = bodyToBody * MotionSheenDriver.lightBaselineBody

        // In-plane delta — how far the apparent light direction has
        // shifted along the screen X and Y axes since baseline. This
        // is smooth and well-defined for every rotation, including
        // pure yaw of a vertical device (which has no signal at all
        // in raw gravity).
        let dx = lightCurrent.x - MotionSheenDriver.lightBaselineBody.x
        let dy = lightCurrent.y - MotionSheenDriver.lightBaselineBody.y

        // Single-pole low-pass to suppress jitter without adding
        // perceptible latency.
        let alpha = 0.18
        smoothedX += alpha * (dx - smoothedX)
        smoothedY += alpha * (dy - smoothedY)

        // Drop a stable copy onto each subscriber. NSHashTable.allObjects
        // is a snapshot so it's safe even if a subscriber removes itself
        // during dispatch.
        let x = smoothedX
        let y = smoothedY
        for subscriber in subscribers.allObjects {
            subscriber.applyTilt(x: x, y: y)
        }
        for binding in parallaxSubscribers.allObjects {
            binding.applyTilt(x: x, y: y)
        }
    }
}
