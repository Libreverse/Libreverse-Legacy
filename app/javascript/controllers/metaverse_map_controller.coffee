import ApplicationController from './application_controller'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import 'leaflet.offline'
import 'leaflet-ajax'
import 'leaflet-spin'
import 'leaflet-sleep'
import 'leaflet.a11y'
import 'leaflet.translate'

# Controller responsible for rendering the synthetic metaverse map using locally bundled Leaflet (CRS.Simple)
export default class extends ApplicationController
  @values =
    dataUrl: String

  connect: ->
    super()
    @initMap()

  initMap: ->
    @element.classList.add('metaverse-map__container')
    unless @hasDataUrlValue
      console.warn('[MetaverseMap] data-url value missing, falling back to /map/data')
      @dataUrlValue = '/map/data'
    console.debug('[MetaverseMap] Fetching map data from', @dataUrlValue)
    @map = L.map(@element,
      crs: L.CRS.Simple
      minZoom: -2
      zoomSnap: 0.25
      wheelPxPerZoomLevel: 80
      attributionControl: false
      zoomControl: false
      # Leaflet.Sleep options
      sleep: true
      sleepTime: 750
      wakeTime: 750
      sleepNote: true
      hoverToWake: true
      wakeMessage: 'The map is getting some much needed Zzz. Click or Hover to Wake it up.'
      sleepOpacity: 0.7
      # Leaflet.a11y enable plugin features
      a11yPlugin: true
    )
    try
      if L.tileLayer?.offline?
        offlineLayer = L.tileLayer.offline('/tiles/{z}/{x}/{y}.png',
          attribution: ''
          minZoom: -2
          maxZoom: 10
          errorTileUrl: ''
        )
        @offlineLayer = offlineLayer
      else
        console.info('[MetaverseMap] leaflet.offline not available (no offline layer created)')
    catch err
      console.warn('[MetaverseMap] Offline layer setup failed', err)

    # Locale / translation loading (execute regardless of offline layer outcome)
    langParam = new URLSearchParams(window.location.search).get('lang')
    htmlLang = document?.documentElement?.lang
    chosen = langParam or htmlLang
    normalize = (loc) =>
      return null unless loc?
      loc.toString().trim().toLowerCase().split(/[-_]/)[0]
    if chosen? and L.translate?.load?
      L.translate.load(normalize(chosen)).catch (e) =>
        console.warn('[MetaverseMap] Translation load failed', chosen, e)
    else if L.translate?.fromUrl?
      L.translate.fromUrl.load().catch (e) =>
        console.warn('[MetaverseMap] Auto translation load failed', e)

    fetch(@dataUrlValue, { headers: { 'Accept': 'application/json' } })
      .then (r) => r.json()
      .then (data) => @renderData(data)
      .catch (e) => console.error('Map data load failed', e)

  renderData: (data) ->
    unless data?.meta?
      console.error('[MetaverseMap] Invalid data payload (missing meta). Aborting render.', data)
      return
    width = data.meta.total_width or 0
    height = data.meta.total_height or 0
    if width <= 0 or height <= 0
      console.warn('[MetaverseMap] Empty dataset; using placeholder extent.')
      width = 1000
      height = 600

    # Add a little top padding so labels placed just ABOVE the rectangle aren't clipped
    top_padding = 60
    @map.fitBounds([[-top_padding, 0], [height, width]])

    labelLayer = L.layerGroup().addTo(@map)
    @labelMarkers = []
    LABEL_ABOVE_OFFSET = 8 # distance above the top edge of the rectangle

    for provider in data.providers
      rect = L.rectangle([[provider.bbox.y_min, provider.bbox.x_min], [provider.bbox.y_max, provider.bbox.x_max]],
        color: provider.color,
        weight: 1,
        fillOpacity: 0.08,
        stroke: true
      )
      rect.addTo(@map).bindPopup("<strong>#{provider.name}</strong><br/>Experiences: #{provider.experience_count}")
      centerLng = (provider.bbox.x_min + provider.bbox.x_max) / 2.0
      # y_min is the TOP edge in CRS.Simple; place label slightly ABOVE that
      labelLat = provider.bbox.y_min - LABEL_ABOVE_OFFSET
      labelHtml = "<div class='metaverse-provider-label__inner' style='--provider-color: #{provider.color};'>#{provider.name}</div>"
      icon = L.divIcon(
        className: 'metaverse-provider-label'
        html: labelHtml
        iconSize: null
        iconAnchor: [0, 0]
      )
      markerLabel = L.marker([labelLat, centerLng], icon: icon, interactive: false).addTo(labelLayer)
      @labelMarkers.push(markerLabel)

    markers = L.layerGroup().addTo(@map)
    for exp in data.experiences
      marker = L.circleMarker([exp.mapped_y, exp.mapped_x],
        radius: 4,
        color: exp.color,
        fillOpacity: 0.85,
        weight: 1
      )
      popup = "<strong>#{exp.title}</strong><br/>Platform: #{exp.platform}<br/><a href='#{exp.url}' data-turbo='true'>Open</a>"
      marker.bindPopup(popup)
      marker.addTo(markers)

    if data?.geojson_url?
      try
        gjLayer = new L.GeoJSON.AJAX(data.geojson_url,
          middleware: (raw) => raw
          pointToLayer: (feature, latlng) =>
            L.circleMarker(latlng, radius: 3, color: '#ffeb3b', weight: 1, fillOpacity: 0.9)
          onEachFeature: (feature, layer) =>
            layer.bindPopup(feature?.properties?.name or 'Feature')
        )
        gjLayer.on 'data:loading', => @map.spin(true)
        gjLayer.on 'data:loaded', => @map.spin(false)
        gjLayer.addTo(@map)
      catch err
        console.warn('[MetaverseMap] GeoJSON AJAX layer failed', err)

    # Defer horizontal centering until elements are in DOM (width known)
    requestAnimationFrame =>
      for m in @labelMarkers when m.getElement?
        el = m.getElement()
        continue unless el?
        w = el.offsetWidth
        # Rebuild icon with computed anchor so Leaflet handles centering (avoids CSS transform side-effects).
        oldIcon = m.options.icon
        newIcon = L.divIcon(
          className: oldIcon.options.className
          html: oldIcon.options.html
          iconSize: [w, el.offsetHeight]
          iconAnchor: [w / 2, 0]
        )
        m.setIcon(newIcon)
