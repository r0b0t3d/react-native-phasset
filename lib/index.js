"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
//@ts-ignore
const react_native_1 = require("react-native");
const { Phasset } = react_native_1.NativeModules;
function isExists({ id, assetType = 'all' }) {
    return Phasset.checkExists({
        id,
        assetType,
    });
}
function requestImage(params) {
    return Phasset.requestImage(params);
}
exports.default = {
    isExists,
    requestImage,
};
//# sourceMappingURL=index.js.map