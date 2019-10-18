"use strict";
var __rest = (this && this.__rest) || function (s, e) {
    var t = {};
    for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0)
        t[p] = s[p];
    if (s != null && typeof Object.getOwnPropertySymbols === "function")
        for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) {
            if (e.indexOf(p[i]) < 0 && Object.prototype.propertyIsEnumerable.call(s, p[i]))
                t[p[i]] = s[p[i]];
        }
    return t;
};
Object.defineProperty(exports, "__esModule", { value: true });
//@ts-ignore
const react_native_1 = require("react-native");
const { Phasset } = react_native_1.NativeModules;
function isExists(_a) {
    var { id, assetType = 'all', groupTypes = 'all' } = _a, others = __rest(_a, ["id", "assetType", "groupTypes"]);
    return Phasset.checkExists(Object.assign({ id,
        assetType,
        groupTypes }, others));
}
function requestImage(params) {
    return Phasset.requestImage(params);
}
exports.default = {
    isExists,
    requestImage,
};
//# sourceMappingURL=index.js.map