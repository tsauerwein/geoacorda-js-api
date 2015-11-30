/**
 * @module geoacorda
 */
goog.provide('geoacorda');
goog.provide('geoacorda.Map');

goog.require('geoacorda.app.MainController');
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
  appElement.attr('ng-controller', 'MainController as ctrl');
  appElement.append(
      angular.element('<div ngeo-map="ctrl.map" class="map"></div>'));
  angular.bootstrap(appElement[0], ['app']);

  this.controller = appElement.controller();

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
  this.controller.showParcel(parcelId, farmId, auth, onLoad, onModify);
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
  this.controller.saveParcel(auth, callback);
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
  this.controller.showParcels(farmId, auth);
};


/**
 * Zoom the map to the commune with the given id.
 *
 * @param {string} communeId The commune id.
 */
geoacorda.Map.prototype.zoomToCommune = function(communeId) {
  this.controller.zoomToCommune(communeId);
};
