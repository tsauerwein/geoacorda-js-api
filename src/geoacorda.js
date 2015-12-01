/**
 * @module geoacorda
 */
goog.provide('geoacorda');
goog.provide('geoacorda.Map');

goog.require('geoacorda.app.MainController');
goog.require('goog.asserts');
goog.require('ngeo.mapDirective');
goog.require('ol.Object');



/**
 * @classdesc
 * A map wrapper.
 *
 * @constructor
 * @extends {ol.Object}
 * @param {geoacordax.MapOptions=} opt_options Options
 */
geoacorda.Map = function(opt_options) {

  var options = goog.isDef(opt_options) ? opt_options : {};

  goog.base(this, {});

  var appElement = angular.element(options.element);
  this.controllerElement = angular.element('<div app-map=""></div>');
  appElement.append(this.controllerElement);
  angular.bootstrap(appElement[0], ['app']);
};
goog.inherits(geoacorda.Map, ol.Object);


/**
 * Show the parcel with the given id.
 *
 * Loads the parcel from a web-service and displays the geometry on the
 * map. The geometry is editable.
 * @param {string} parcelId The parcel id.
 * @param {string} farmId The farm id.
 * @param {geoacordax.AuthOptions} auth Authentication.
 * @param {function(string, ol.Feature)} onLoad Called with the status
 *    ('success' or 'error') as first parameter and the parcel feature as
 *    second parameter.
 * @param {function(string, number, ol.geom.Geometry, boolean)} onModify Called
 *    when the geometry has changed.
 */
geoacorda.Map.prototype.showParcel =
    function(parcelId, farmId, auth, onLoad, onModify) {
  this.getController_().showParcel(parcelId, farmId, auth, onLoad, onModify);
};


/**
 * Save a previously loaded parcel.
 *
 * @param {geoacordax.AuthOptions} auth Authentication.
 * @param {function(string, Object)} callback Called with the status
 *    ('success' or 'error') as first parameter and informations about the
 *    parcel as second argument.
 */
geoacorda.Map.prototype.saveParcel = function(auth, callback) {
  this.getController_().saveParcel(auth, callback);
};


/**
 * Show all parcels for a farm with the given id.
 *
 * Loads the parcel from a web-service and displays the geometries on the
 * map.
 * @param {string} farmId The farm id.
 * @param {geoacordax.AuthOptions} auth Authentication.
 */
geoacorda.Map.prototype.showParcels = function(farmId, auth) {
  this.getController_().showParcels(farmId, auth);
};


/**
 * Zoom the map to the commune with the given id.
 *
 * @param {string} communeId The commune id.
 */
geoacorda.Map.prototype.zoomToCommune = function(communeId) {
  this.getController_().zoomToCommune(communeId);
};


/**
 * Get the main controller.
 *
 * @return {geoacorda.app.MainController} The controller.
 * @private
 */
geoacorda.Map.prototype.getController_ = function() {
  var controller = this.controllerElement.controller('appMap');
  goog.asserts.assertInstanceof(controller, geoacorda.app.MainController);
  return controller;
};
