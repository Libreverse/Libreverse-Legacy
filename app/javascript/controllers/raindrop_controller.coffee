###
# RaindropController
#
# Usage:
#   <div data-controller="raindrop"
#        data-raindrop-background-url-value=""
#        data-raindrop-rainyday-options-value="{&quot;blur&quot;:5, &quot;fps&quot;:30}">
#     <template data-raindrop-target="source">/images/bg.avif</template>
#   </div>
#
# The 'rainydayOptions' value can be set to any RainyDay.js options (see library docs).
###
import ApplicationController from "./application_controller"
import "../libs/rainyday.js"
import { setupLocomotiveScrollParallax } from "./parallax_utils.coffee"
# Vite-imported backgrounds for inline asset URLs
import cloudsBg from "../../images/clouds.avif"
import garageBg from "../../images/garage.avif"

###*
 * Manages an iframe containing the RaindropFX effect to isolate its context.
###
export default class extends ApplicationController
  @values =
    backgroundUrl: String
    rainydayOptions: { type: Object, default: {} }
  @targets = ["source"]

  connect: ->
    super.connect()
    @active = true
    @setupRainyDay()
    @setupParallax()
    @setupResizeListener()
    return

  disconnect: ->
    super.disconnect()
    @active = false
    @rainyday?.destroy()
    @rainyday = null
    @removeParallax?()
    @removeResizeListener?()
    return

  setupRainyDay: ->
    # Fallback: if no data value, try hidden template, then path-map, then default
    unless @hasBackgroundUrlValue
      if @hasSourceTarget and @sourceTarget?.textContent?
        url = @sourceTarget.textContent.trim()
        if url?.length > 0 then @backgroundUrlValue = url

      unless @hasBackgroundUrlValue
        mapped = @bgFromPath(window?.location?.pathname or "/")
        if mapped? then @backgroundUrlValue = mapped

      unless @hasBackgroundUrlValue
        @backgroundUrlValue = garageBg

    unless @hasBackgroundUrlValue
      return

    # Remove any previous canvas
    for child in @element.children
      if child.tagName?.toLowerCase() is 'canvas'
        child.remove()

    img = new window.Image()
    img.crossOrigin = "anonymous"
    img.src = @backgroundUrlValue

    img.onload = =>
      return unless @active and @element.isConnected
      # Create a canvas that fills the parent
      canvas = document.createElement('canvas')
      canvas.width = @element.offsetWidth
      canvas.height = @element.offsetHeight
      canvas.style.position = 'absolute'
      canvas.style.top = 0
      canvas.style.left = 0
      canvas.style.width = '100%'
      canvas.style.height = '100%'
      canvas.style.pointerEvents = 'none'
      canvas.className = 'raindrop-canvas'
      @element.appendChild(canvas)

      # Default config matching raindrop-fx as closely as possible
      defaultRainyDayOptions =
        opacity: 1
        blur: 20
        fps: 120
        enableCollisions: true
        enableSizeChange: true
        gravityThreshold: 3
        gravityAngle: Math.PI / 2
        gravityAngleVariance: 0
        reflectionScaledownFactor: 5
        reflectionDropMappingWidth: 80
        reflectionDropMappingHeight: 80
        width: canvas.width
        height: canvas.height
        position: 'absolute'
        top: 0
        left: 0
        parentElement: @element
        canvas: canvas
        image: img

      # Merge options: background image, parent, canvas, size, plus user config
      options = Object.assign {}, defaultRainyDayOptions, @rainydayOptionsValue

      @rainyday = new window.RainyDay(options)

      min = 8
      base = 8
      rate = 1
      speed = 25
      @rainyday.rain([[min, base, rate]], speed)
    return

  setupParallax: ->
    return unless @element.hasAttribute?('data-scroll')
    speed = parseFloat(@element.getAttribute('data-scroll-speed') or '-2')
    @removeParallax = setupLocomotiveScrollParallax(@element, speed, @)
    return

  setupResizeListener: ->
    @handleResize = =>
      @updateRainyDayDimensions()

    window.addEventListener 'debounced:resize', @handleResize
    @removeResizeListener = =>
      window.removeEventListener 'debounced:resize', @handleResize
    return

  updateRainyDayDimensions: ->
    return unless @active and @rainyday?
    # Remove and re-setup RainyDay to update canvas size
    @rainyday.destroy?()
    @rainyday = null
    @setupRainyDay()
    return

  bgFromPath: (path) ->
    # Path prefix -> image map
    mapping =
      "/blog": cloudsBg
      # add more: "/search": someOtherBg

    for prefix, url of mapping when path.indexOf(prefix) is 0
      return url
    null
