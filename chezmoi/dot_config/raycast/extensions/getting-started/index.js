"use strict";
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// src/index.tsx
var index_exports = {};
__export(index_exports, {
  default: () => Command
});
module.exports = __toCommonJS(index_exports);
var import_api = require("@raycast/api");
var import_jsx_runtime = require("react/jsx-runtime");
function Command() {
  return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_api.List, { children: [
    /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_api.List.Section, { title: "Basics", children: [
      /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LinkListItem, { title: "Familiarize yourself with Raycast", link: "https://raycast.com/manual" }),
      /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LinkListItem, { title: "Install extensions from our public store", link: "https://www.raycast.com/store" }),
      /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LinkListItem, { title: "Build your own extensions with our API", link: "https://developers.raycast.com" }),
      /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LinkListItem, { title: "Invite your teammates", link: "raycast://organizations/jjkself/manage" })
    ] }),
    /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_api.List.Section, { title: "Next Steps", children: [
      /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LinkListItem, { title: "Join the Raycast community", link: "https://raycast.com/community" }),
      /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LinkListItem, { title: "Stay up to date via Twitter", link: "https://twitter.com/raycastapp" })
    ] })
  ] });
}
function LinkListItem(props) {
  return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(
    import_api.List.Item,
    {
      title: props.title,
      icon: import_api.Icon.Link,
      accessories: [{ text: props.link }],
      actions: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_api.ActionPanel, { children: [
        /* @__PURE__ */ (0, import_jsx_runtime.jsx)(import_api.Action.OpenInBrowser, { url: props.link }),
        /* @__PURE__ */ (0, import_jsx_runtime.jsx)(import_api.Action.CopyToClipboard, { title: "Copy Link", content: props.link })
      ] })
    }
  );
}
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsiLi4vLi4vLi4vLi4vU2NyaXB0cy9SYXljYXN0L3JheWNhc3QtZXh0ZW5zaW9ucy9nZXR0aW5nLXN0YXJ0ZWQvc3JjL2luZGV4LnRzeCJdLAogICJzb3VyY2VzQ29udGVudCI6IFsiaW1wb3J0IHsgQWN0aW9uUGFuZWwsIEFjdGlvbiwgSWNvbiwgTGlzdCB9IGZyb20gXCJAcmF5Y2FzdC9hcGlcIjtcblxuZXhwb3J0IGRlZmF1bHQgZnVuY3Rpb24gQ29tbWFuZCgpIHtcbiAgcmV0dXJuIChcbiAgICA8TGlzdD5cbiAgICAgIDxMaXN0LlNlY3Rpb24gdGl0bGU9XCJCYXNpY3NcIj5cbiAgICAgICAgPExpbmtMaXN0SXRlbSB0aXRsZT1cIkZhbWlsaWFyaXplIHlvdXJzZWxmIHdpdGggUmF5Y2FzdFwiIGxpbms9XCJodHRwczovL3JheWNhc3QuY29tL21hbnVhbFwiIC8+XG4gICAgICAgIDxMaW5rTGlzdEl0ZW0gdGl0bGU9XCJJbnN0YWxsIGV4dGVuc2lvbnMgZnJvbSBvdXIgcHVibGljIHN0b3JlXCIgbGluaz1cImh0dHBzOi8vd3d3LnJheWNhc3QuY29tL3N0b3JlXCIgLz5cbiAgICAgICAgPExpbmtMaXN0SXRlbSB0aXRsZT1cIkJ1aWxkIHlvdXIgb3duIGV4dGVuc2lvbnMgd2l0aCBvdXIgQVBJXCIgbGluaz1cImh0dHBzOi8vZGV2ZWxvcGVycy5yYXljYXN0LmNvbVwiIC8+XG4gICAgICAgIDxMaW5rTGlzdEl0ZW0gdGl0bGU9XCJJbnZpdGUgeW91ciB0ZWFtbWF0ZXNcIiBsaW5rPVwicmF5Y2FzdDovL29yZ2FuaXphdGlvbnMvamprc2VsZi9tYW5hZ2VcIiAvPlxuICAgICAgPC9MaXN0LlNlY3Rpb24+XG4gICAgICA8TGlzdC5TZWN0aW9uIHRpdGxlPVwiTmV4dCBTdGVwc1wiPlxuICAgICAgICA8TGlua0xpc3RJdGVtIHRpdGxlPVwiSm9pbiB0aGUgUmF5Y2FzdCBjb21tdW5pdHlcIiBsaW5rPVwiaHR0cHM6Ly9yYXljYXN0LmNvbS9jb21tdW5pdHlcIiAvPlxuICAgICAgICA8TGlua0xpc3RJdGVtIHRpdGxlPVwiU3RheSB1cCB0byBkYXRlIHZpYSBUd2l0dGVyXCIgbGluaz1cImh0dHBzOi8vdHdpdHRlci5jb20vcmF5Y2FzdGFwcFwiIC8+XG4gICAgICA8L0xpc3QuU2VjdGlvbj5cbiAgICA8L0xpc3Q+XG4gICk7XG59XG5cbmZ1bmN0aW9uIExpbmtMaXN0SXRlbShwcm9wczogeyB0aXRsZTogc3RyaW5nOyBsaW5rOiBzdHJpbmcgfSkge1xuICByZXR1cm4gKFxuICAgIDxMaXN0Lkl0ZW1cbiAgICAgIHRpdGxlPXtwcm9wcy50aXRsZX1cbiAgICAgIGljb249e0ljb24uTGlua31cbiAgICAgIGFjY2Vzc29yaWVzPXtbeyB0ZXh0OiBwcm9wcy5saW5rIH1dfVxuICAgICAgYWN0aW9ucz17XG4gICAgICAgIDxBY3Rpb25QYW5lbD5cbiAgICAgICAgICA8QWN0aW9uLk9wZW5JbkJyb3dzZXIgdXJsPXtwcm9wcy5saW5rfSAvPlxuICAgICAgICAgIDxBY3Rpb24uQ29weVRvQ2xpcGJvYXJkIHRpdGxlPVwiQ29weSBMaW5rXCIgY29udGVudD17cHJvcHMubGlua30gLz5cbiAgICAgICAgPC9BY3Rpb25QYW5lbD5cbiAgICAgIH1cbiAgICAvPlxuICApO1xufVxuIl0sCiAgIm1hcHBpbmdzIjogIjs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7QUFBQTtBQUFBO0FBQUE7QUFBQTtBQUFBO0FBQUEsaUJBQWdEO0FBSzFDO0FBSFMsU0FBUixVQUEyQjtBQUNoQyxTQUNFLDZDQUFDLG1CQUNDO0FBQUEsaURBQUMsZ0JBQUssU0FBTCxFQUFhLE9BQU0sVUFDbEI7QUFBQSxrREFBQyxnQkFBYSxPQUFNLHFDQUFvQyxNQUFLLDhCQUE2QjtBQUFBLE1BQzFGLDRDQUFDLGdCQUFhLE9BQU0sNENBQTJDLE1BQUssaUNBQWdDO0FBQUEsTUFDcEcsNENBQUMsZ0JBQWEsT0FBTSwwQ0FBeUMsTUFBSyxrQ0FBaUM7QUFBQSxNQUNuRyw0Q0FBQyxnQkFBYSxPQUFNLHlCQUF3QixNQUFLLDBDQUF5QztBQUFBLE9BQzVGO0FBQUEsSUFDQSw2Q0FBQyxnQkFBSyxTQUFMLEVBQWEsT0FBTSxjQUNsQjtBQUFBLGtEQUFDLGdCQUFhLE9BQU0sOEJBQTZCLE1BQUssaUNBQWdDO0FBQUEsTUFDdEYsNENBQUMsZ0JBQWEsT0FBTSwrQkFBOEIsTUFBSyxrQ0FBaUM7QUFBQSxPQUMxRjtBQUFBLEtBQ0Y7QUFFSjtBQUVBLFNBQVMsYUFBYSxPQUF3QztBQUM1RCxTQUNFO0FBQUEsSUFBQyxnQkFBSztBQUFBLElBQUw7QUFBQSxNQUNDLE9BQU8sTUFBTTtBQUFBLE1BQ2IsTUFBTSxnQkFBSztBQUFBLE1BQ1gsYUFBYSxDQUFDLEVBQUUsTUFBTSxNQUFNLEtBQUssQ0FBQztBQUFBLE1BQ2xDLFNBQ0UsNkNBQUMsMEJBQ0M7QUFBQSxvREFBQyxrQkFBTyxlQUFQLEVBQXFCLEtBQUssTUFBTSxNQUFNO0FBQUEsUUFDdkMsNENBQUMsa0JBQU8saUJBQVAsRUFBdUIsT0FBTSxhQUFZLFNBQVMsTUFBTSxNQUFNO0FBQUEsU0FDakU7QUFBQTtBQUFBLEVBRUo7QUFFSjsiLAogICJuYW1lcyI6IFtdCn0K
