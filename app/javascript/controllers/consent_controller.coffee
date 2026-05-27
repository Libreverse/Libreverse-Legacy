import * as Turbo from "@hotwired/turbo"
import ApplicationController from "./application_controller"
import { get, post } from "@rails/request.js"
import Cookies from "js-cookie"

# ConsentController: handles UX and triggers ConsentReflex
export default class extends ApplicationController
  @targets = ["checkbox", "form"]

  connect: ->
    super.connect()
    # Check if consent already given via cookie (for UI purposes)
    if Cookies.get("consent_ui_preference") is "accepted"
      @hideConsentUI()
    return

  accept: (event) ->
    event.preventDefault()
    rememberOptIn = if @hasCheckboxTarget and @checkboxTarget.checked then "1" else "0"

    # Set client-side cookie for immediate UI feedback
    Cookies.set("consent_ui_preference", "accepted", { expires: 365 })

    # Collect invisible captcha data
    captchaData = @getCaptchaData()

    post("/consent/accept", {
      body: {
        remember_opt_in: rememberOptIn,
        ...captchaData
      }
      responseKind: "turbo-stream"
    }).then (response) =>
      if response.ok then response.html.then (html) => Turbo.renderStreamMessage html

  decline: (event) ->
    event.preventDefault()

    # Set client-side cookie for declined
    Cookies.set("consent_ui_preference", "declined", { expires: 30 })

    # Collect invisible captcha data
    captchaData = @getCaptchaData()

    post("/consent/decline", {
      body: captchaData
      responseKind: "turbo-stream"
    }).then (response) =>
      if response.ok then response.html.then (html) => Turbo.renderStreamMessage html

  showScreen: (event) ->
    event.preventDefault()
    get("/consent/screen", {
      responseKind: "turbo-stream"
    }).then (response) =>
      if response.ok then response.html.then (html) => Turbo.renderStreamMessage html

  hideConsentUI: ->
    # Hide consent UI elements if already accepted
    consentElements = document.querySelectorAll('.consent-overlay, .consent-banner')
    consentElements.forEach (el) =>
      el.style.display = 'none'

  # Collect invisible captcha data from the current page
  getCaptchaData: ->
    data = {}

    # Find honeypot field (has random hex name)
    honeypotField = document.querySelector('input[type="text"][name^=""][style*="display:none"], input[type="text"][name^=""][style*="visibility:hidden"]')
    if honeypotField?.name?.match(/^[a-f0-9]{8,}$/)
      data[honeypotField.name] = honeypotField.value or ""

    # Find timestamp field
    timestampField = document.querySelector('input[name="invisible_captcha_timestamp"]')
    if timestampField
      data.invisible_captcha_timestamp = timestampField.value

    data
