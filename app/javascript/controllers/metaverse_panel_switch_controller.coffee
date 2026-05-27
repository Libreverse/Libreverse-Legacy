import ApplicationController from './application_controller'

# Controls sliding between 2D (Leaflet) and upcoming 3D panel.
# Provides accessible toggle buttons and preserves current active index in a value (future: persist in localStorage).
export default class extends ApplicationController
  @targets = ['track', 'panel2d', 'panel3d', 'toggle', 'btn2d', 'btn3d']
  @values = { activeIndex: { type: Number, default: 0 } }

  connect: ->
    super()
    # Restore persisted index if available
    try
      stored = window?.localStorage?.getItem('metaversePanelActiveIndex')
      if stored?
        parsed = parseInt(stored, 10)
        if isFinite(parsed) and parsed in [0, 1]
          @activeIndexValue = parsed
    catch e
      console?.warn('[MetaversePanelSwitch] persistence load failed', e)
    @applyState()

  show2d: (e) ->
    e?.preventDefault()
    @activeIndexValue = 0
    @applyState()

  show3d: (e) ->
    e?.preventDefault()
    @activeIndexValue = 1
    @applyState()

  applyState: ->
    # Clamp index (future-proof if more panels added)
    total = 2
    idx = Math.max(0, Math.min(@activeIndexValue, total - 1))
    @activeIndexValue = idx
    # Toggle classes on panels
    @panel2dTarget.classList.toggle('is-active', idx is 0)
    @panel2dTarget.classList.toggle('is-inactive', idx isnt 0)
    @panel3dTarget.classList.toggle('is-active', idx is 1)
    @panel3dTarget.classList.toggle('is-inactive', idx isnt 1)

    # Slide track
    offsetPercent = (idx * -100)
    @trackTarget.style.transition = ''
    @trackTarget.style.transform = "translate3d(#{offsetPercent}%,0,0)"
    # Persist state (best-effort)
    try window?.localStorage?.setItem('metaversePanelActiveIndex', String(idx)) catch e then null

    # Lazy load hook when 3D panel first becomes active
    if idx is 1 and not @panel3dTarget.dataset.lazyLoaded?
      @lazyLoad3D()

    # Update buttons
    @btn2dTarget.classList.toggle('is-current', idx is 0)
    @btn3dTarget.classList.toggle('is-current', idx is 1)
    @btn2dTarget.setAttribute('aria-pressed', (idx is 0).toString())
    @btn3dTarget.setAttribute('aria-pressed', (idx is 1).toString())

  # In case we later want keyboard shortcuts
  keydown: (e) ->
    return unless ['ArrowLeft', 'ArrowRight'].includes(e.key)
    if e.key is 'ArrowLeft' then @show2d() else @show3d()

  disconnect: ->
    super()

  # --- Lazy Load 3D Panel ---
  lazyLoad3D: ->
    @panel3dTarget.dataset.lazyLoaded = 'true'
    try
      evt = new CustomEvent('metaverse:panel:3d:activate', detail: {})
      @panel3dTarget.dispatchEvent(evt)
    catch err
      console?.warn('[MetaversePanelSwitch] custom event dispatch failed', err)
    # Optional dynamic import if developer sets data-import attribute
    modPath = @panel3dTarget.dataset.import
    return unless modPath?
    import(modPath).then (mod) =>
      if typeof mod?.default is 'function'
        try mod.default(@panel3dTarget)
        catch e then console.error('[MetaversePanelSwitch] 3D module init failed', e)
    .catch (e) =>
      console.error('[MetaversePanelSwitch] 3D lazy module load failed', e)

  # Determine whether the map is currently in its 'sleeping' state.
  # We infer this via presence + visible opacity of .sleep-note (Leaflet.Sleep overlay)
  mapIsSleeping: ->
    return false unless @activeIndexValue is 0 # Only relevant on 2D panel
    note = @panel2dTarget?.querySelector('.sleep-note') or @element.querySelector('.sleep-note')
    return false unless note?
    comp = window.getComputedStyle(note)
    op = parseFloat(comp.opacity) or 0
    op > 0.4
