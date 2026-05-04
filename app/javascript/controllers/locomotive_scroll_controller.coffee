import { Controller } from "@hotwired/stimulus"
import LocomotiveScroll from "locomotive-scroll"

export default class extends Controller
  connect: ->
    @scroll = undefined
    @boundDestroyIfNeeded = @destroyIfNeeded.bind(@)
    @boundDestroy = @destroy.bind(@)
    @handleTurboLoad = @handleTurboLoad.bind(@)
    @handleTurboRender = @handleTurboRender.bind(@)
    @setupEventListeners()
    @init()
    return

  disconnect: ->
    @destroy()
    @removeEventListeners()
    return

  init: ->
    try
      @scroll ||= new LocomotiveScroll({
        el: @element or document.querySelector('[data-scroll-container]') or document.body,
        smooth: true,
        repeat: true,
        gestureDirection: 'vertical',
        reloadOnContextChange: false,
        resetNativeScroll: false,
        smartphone: {
          smooth: true
        },
        tablet: {
          smooth: true
        }
      })

      # Expose globally for glass container integration
      window.locomotiveScroll = @scroll

      # Dispatch custom event when scroll updates
      @scroll.on 'scroll', (args) =>
        event = new CustomEvent('locomotive-scroll', {
          detail: args
        })
        document.dispatchEvent(event)
    catch error
      console.error "Failed to initialize LocomotiveScroll:", error
    return

  destroy: ->
    if @scroll?
      @scroll.destroy?()
      @scroll = undefined
      # Clean up global reference
      window.locomotiveScroll = undefined
    return

  resume: ->
    if @scroll?
      if typeof @scroll.update is "function"
        @scroll.update()
      else if typeof @scroll.start is "function"
        @scroll.start()
    return

  destroyIfNeeded: (event) =>
    if @scroll? and (not event or event.target.controller isnt "Turbo.FrameController")
      @destroy()
    return

  handleTurboLoad: =>
    if @scroll?
      @resume()
    else
      @init()
    return

  handleTurboRender: =>
    unless @scroll?
      @init()
    return

  setupEventListeners: ->
    document.addEventListener "turbo:load", @handleTurboLoad
    document.addEventListener "turbo:before-cache", @boundDestroyIfNeeded
    document.addEventListener "turbo:before-render", @boundDestroyIfNeeded
    document.addEventListener "turbo:render", @handleTurboRender
    window.addEventListener "beforeunload", @boundDestroy
    return

  removeEventListeners: ->
    document.removeEventListener "turbo:load", @handleTurboLoad
    document.removeEventListener "turbo:before-cache", @boundDestroyIfNeeded
    document.removeEventListener "turbo:before-render", @boundDestroyIfNeeded
    document.removeEventListener "turbo:render", @handleTurboRender
    window.removeEventListener "beforeunload", @boundDestroy
    return
