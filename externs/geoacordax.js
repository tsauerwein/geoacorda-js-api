/**
 * @type {Object}
 * @private
 */
var geoacordax;


/**
 * Map options.
 * @typedef {{
 *    element: (Element|string),
 *    url: (string)
 * }}
 */
geoacordax.MapOptions;

/**
 * The map element.
 * @type {Element|string}
 */
geoacordax.MapOptions.prototype.element;

/**
 * The base url to the web-services.
 * @type {string}
 */
geoacordax.MapOptions.prototype.url;


/**
 * Authentication options.
 * @typedef {{
 *    role: (string),
 *    token: (string)
 * }}
 */
geoacordax.AuthOptions;

/**
 * The role.
 * @type {string}
 */
geoacordax.AuthOptions.prototype.role;

/**
 * The token.
 * @type {string}
 */
geoacordax.AuthOptions.prototype.token;
