// node legacy.js
//
// This demonstrates that VexFlow can be imported even with older versions of Node JS (e.g. v11.15.0).
// Those older versions do not support `globalThis`, but provide `global` and `this` as the global object.

// In Node v11.15.0, the require path must look like one of the following:
//   require('../../build/cjs/vexflow')
//   require('../../build/cjs/vexflow.js')
// The usual require('vexflow') will NOT work because legacy Node JS does not support self referencing via
// the exports field of `vexflow/package.json`.
const Vex = require('../../build/cjs/vexflow');

const { Flow, Stave, Accidental, Font } = Vex.Flow;

console.log('VexFlow BUILD: ' + Flow.BUILD);

console.log("Stave's default TEXT_FONT is [" + Font.toCSSString(Stave.TEXT_FONT) + ']');

console.log("This accidental's type is " + new Accidental(`##`).type);
