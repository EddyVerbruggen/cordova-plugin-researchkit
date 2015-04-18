var cordova = require("cordova");

function ResearchKit() {
}

ResearchKit.prototype.isAvailable = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "ResearchKit", "isAvailable", []);
};

ResearchKit.prototype.survey = function (options, successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "ResearchKit", "survey", [options]);
};

ResearchKit.install = function () {
  if (!window.plugins) {
    window.plugins = {};
  }

  window.plugins.researchkit = new ResearchKit();
  return window.plugins.researchkit;
};

cordova.addConstructor(ResearchKit.install);