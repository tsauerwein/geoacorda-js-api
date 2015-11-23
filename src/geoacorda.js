/**
 * @module geoacorda
 */
goog.provide('geoacorda');
goog.provide('geoacorda.Map');

goog.require('goog.asserts');
goog.require('goog.net.XhrIo');
goog.require('ol.Collection');
goog.require('ol.Map');
goog.require('ol.Object');
goog.require('ol.View');
goog.require('ol.format.GeoJSON');
goog.require('ol.interaction.Modify');
goog.require('ol.interaction.Select');
goog.require('ol.layer.Tile');
goog.require('ol.layer.Vector');
goog.require('ol.source.OSM');
goog.require('ol.source.Vector');
goog.require('ol.style.Fill');
goog.require('ol.style.Stroke');
goog.require('ol.style.Style');



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

  goog.base(this, options);

  this.map = this.createMap_(options.element);
  this.parcelSource = null;
  this.parcelLayer = null;
  this.parcelsLayer = null;
  this.parcel = null;
  this.selectInteraction = null;
  this.modifyInteraction = null;

};
goog.inherits(geoacorda.Map, ol.Object);


/**
 * @param {string|Element} element The map element.
 * @return {ol.Map} The map.
 * @private
 */
geoacorda.Map.prototype.createMap_ = function(element) {
  return new ol.Map({
    target: element,
    layers: [
      new ol.layer.Tile({
        source: new ol.source.OSM()
      })
    ],
    view: new ol.View({
      center: [738496, 5864210],
      zoom: 12
    })
  });
};


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
  this.resetParcelLayer_();
  this.disableEditing_();
  this.addParcelsLayer_(farmId, auth);

  // fake making a request
  goog.net.XhrIo.send('data/parcel.geojson', goog.bind(function(e) {
    var xhr = /** @type {goog.net.XhrIo} */ (e.target);
    if (!xhr.isSuccess()) {
      onLoad('error', null);
    }
    var response = xhr.getResponseJson();
    goog.asserts.assert(response !== undefined);
    var format = new ol.format.GeoJSON();
    var features = format.readFeatures(response,
        {featureProjection: 'EPSG:3857'});

    this.parcel = features[0];
    this.parcelSource = new ol.source.Vector({
      features: features
    });
    this.parcelLayer = new ol.layer.Vector({
      source: this.parcelSource,
      style: new ol.style.Style({
        fill: new ol.style.Fill({
          color: [235, 84, 42, 0.5]
        }),
        stroke: new ol.style.Stroke({
          color: [235, 84, 42, 1],
          width: 3
        })
      })
    });
    this.map.addLayer(this.parcelLayer);
    this.map.getView().fit(this.parcel.getGeometry(), this.map.getSize());
    this.enableEditing_(parcelId, this.parcel, onModify);
    onLoad('success', this.parcel);
  }, this));
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
  if (this.parcel === null) {
    callback('error', null);
    return;
  }
  // make a request to save the parcel
  callback('success', {
    geometry: this.parcel.getGeometry(),
    area: 1234,
    geometrySau: this.parcel.getGeometry(),
    areaSau: 2345
  });
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
  this.resetParcelLayer_();
  this.disableEditing_();
  this.addParcelsLayer_(farmId, auth);

  var parcelsSource = this.parcelsLayer.getSource();
  parcelsSource.once('change', goog.bind(function() {
    if (parcelsSource.getFeatures().length > 0) {
      this.map.getView().fit(parcelsSource.getExtent(), this.map.getSize());
    }
  }, this));
};


/**
 * @param {string} farmId The farm id.
 * @param {geoacordax.AuthOptions} auth Authentication.
 * @private
 */
geoacorda.Map.prototype.addParcelsLayer_ = function(farmId, auth) {
  this.parcelsLayer = new ol.layer.Vector({
    source: new ol.source.Vector({
      url: 'data/parcels.geojson',
      format: new ol.format.GeoJSON()
    }),
    style: new ol.style.Style({
      fill: new ol.style.Fill({
        color: [81, 125, 67, 0.3]
      }),
      stroke: new ol.style.Stroke({
        color: [81, 125, 67, 0.8],
        width: 2
      })
    })
  });
  this.map.addLayer(this.parcelsLayer);
};


/**
 * Zoom the map to the commune with the given id.
 *
 * @param {string} communeId The commune id.
 */
geoacorda.Map.prototype.zoomToCommune = function(communeId) {
  // make request to get extent
  this.map.getView().fit(
      ol.proj.transformExtent(
          [6.579, 46.574, 6.63, 46.604], 'EPSG:4326', 'EPSG:3857'),
      this.map.getSize());
};


/**
 * @param {string} parcelId The parcel id.
 * @param {ol.Feature} parcel The parcel to edit.
 * @param {function(string, number, ol.geom.Geometry, boolean)} onModify Called
 *    when the geometry has changed.
 * @private
 */
geoacorda.Map.prototype.enableEditing_ = function(parcelId, parcel, onModify) {
  var modifyFeatures = new ol.Collection([parcel]);
  this.selectInteraction = new ol.interaction.Select({
    features: modifyFeatures,
    layers: [this.parcelLayer]
  });
  this.map.addInteraction(this.selectInteraction);
  this.modifyInteraction = new ol.interaction.Modify({
    features: modifyFeatures
  });
  this.modifyInteraction.on('modifyend', function() {
    var geom = parcel.getGeometry();
    goog.asserts.assert(geom !== undefined);
    onModify(parcelId, 1234, geom, false);
  });
  this.map.addInteraction(this.modifyInteraction);
};


/**
 * @private
 */
geoacorda.Map.prototype.disableEditing_ = function() {
  if (this.modifyInteraction !== null) {
    this.map.removeInteraction(this.selectInteraction);
    this.map.removeInteraction(this.modifyInteraction);
  }
};


/**
 * @private
 */
geoacorda.Map.prototype.resetParcelLayer_ = function() {
  if (this.parcelSource !== null) {
    this.map.removeLayer(this.parcelLayer);
    this.parcelSource = null;
    this.parcelLayer = null;
    this.parcel = null;
  }
  if (this.parcelsLayer !== null) {
    this.map.removeLayer(this.parcelsLayer);
  }
};
