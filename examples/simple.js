goog.provide('simple');

goog.require('geoacorda');

var auth = {role: 'user', token: 'ABCD'};
var map = new geoacorda.Map({
  element: 'map',
  url: 'https://geoacorda.ch/api'
});

var onParcelGeometryChanged = function(parcelId, area, geometry, overlaps) {
  console.log('Parcel has changed ' + parcelId);
};

$('#showParcel').click(function() {
  map.showParcel(
      'parcel-id-1', 'farm-id-1', auth, function(status, parcelFeature) {
        if (status === 'error') {
          // error handling
        } else {
          console.log(parcelFeature.get('id'));
          $('#saveParcel').show();
        }
      }, onParcelGeometryChanged);
});

$('#saveParcel').click(function() {
  map.saveParcel(auth, function(status, result) {
    if (status === 'error') {
      // error handling
    } else {
      console.log(result.area);
      console.log(result.areaSau);
    }
  });
});

$('#showParcels').click(function() {
  $('#saveParcel').hide();
  map.showParcels('farm-id-1', auth, function(status, parcelFeatures) {
    if (status === 'error') {
      // error handling
    } else {
      console.log(parcelFeatures[0].get('id'));
    }
  });
});

$('#zoomToCommune').click(function() {
  map.zoomToCommune('1234');
});
