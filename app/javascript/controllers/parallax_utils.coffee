# parallax_utils.coffee
# Shared utility for LocomotiveScroll-based parallax effects

scrollYFromDetail = (detail) ->
  scroll = detail?.scroll
  if typeof scroll is "number"
    scroll
  else if scroll?.y?
    scroll.y
  else
    0

# Sets up a parallax effect on the given element using LocomotiveScroll v5.
# Listens to the locomotive-scroll custom event dispatched by LocomotiveScrollController.
# Returns a cleanup function to remove the effect.
# Usage:
#   cleanup = setupLocomotiveScrollParallax(element, speed, context)
#   cleanup() # to remove
setupLocomotiveScrollParallax = (element, speed = -2, context = null) ->
  handler = (event) =>
    y = scrollYFromDetail(event?.detail)
    element.style.transform = "translate3d(0, #{y * speed * 0.1}px, 0)"

  handler = handler.bind(context) if context?

  document.addEventListener "locomotive-scroll", handler

  ->
    document.removeEventListener "locomotive-scroll", handler
    element.style.transform = ""

# Export for use in controllers
export { setupLocomotiveScrollParallax }
