({
    handleForceRefreshViewForLWC: function (component) {
        component.find("cmrHighlightPanel").fireRefresh(); //refreshTimeline();
    }
})