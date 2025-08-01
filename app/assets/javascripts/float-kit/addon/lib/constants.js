export const FLOAT_UI_PLACEMENTS = [
  "top",
  "top-start",
  "top-end",
  "right",
  "right-start",
  "right-end",
  "bottom",
  "bottom-start",
  "bottom-end",
  "left",
  "left-start",
  "left-end",
];

export const VISIBILITY_OPTIMIZERS = {
  FLIP: "flip",
  AUTO_PLACEMENT: "autoPlacement",
};

export const TOOLTIP = {
  options: {
    animated: true,
    arrow: true,
    beforeTrigger: null,
    closeOnClickOutside: true,
    closeOnEscape: true,
    closeOnScroll: true,
    component: null,
    content: null,
    identifier: null,
    interactive: false,
    listeners: false,
    maxWidth: 350,
    data: null,
    offset: 10,
    triggers: { mobile: ["click"], desktop: ["hover", "click"] },
    untriggers: { mobile: ["click"], desktop: ["hover", "click"] },
    placement: "top",
    visibilityOptimizer: VISIBILITY_OPTIMIZERS.FLIP,
    fallbackPlacements: FLOAT_UI_PLACEMENTS,
    autoUpdate: true,
    trapTab: true,
    onClose: null,
    onShow: null,
    onRegisterApi: null,
    updateOnScroll: true,
  },
  portalOutletId: "d-tooltip-portal-outlet",
};

export const MENU = {
  options: {
    animated: true,
    arrow: false,
    autofocus: false,
    beforeTrigger: null,
    closeOnEscape: true,
    closeOnClickOutside: true,
    closeOnScroll: false,
    component: null,
    content: null,
    identifier: null,
    interactive: true,
    listeners: false,
    maxWidth: 400,
    data: null,
    offset: 10,
    triggers: ["click"],
    untriggers: ["click"],
    placement: "bottom-start",
    visibilityOptimizer: VISIBILITY_OPTIMIZERS.FLIP,
    fallbackPlacements: FLOAT_UI_PLACEMENTS,
    autoUpdate: true,
    trapTab: true,
    onClose: null,
    onShow: null,
    onRegisterApi: null,
    modalForMobile: false,
    inline: null,
    groupIdentifier: null,
    parentIdentifier: null,
    triggerClass: null,
    contentClass: null,
    class: null,
    updateOnScroll: true,
  },
  portalOutletId: "d-menu-portal-outlet",
};

import DDefaultToast from "float-kit/components/d-default-toast";

export const TOAST = {
  options: {
    autoClose: true,
    duration: "short",
    component: DDefaultToast,
    showProgressBar: false,
    views: ["desktop", "mobile"],
  },
};
