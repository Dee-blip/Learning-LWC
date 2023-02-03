({
    handleForceRefreshViewForLWC: function (component) {
        component.find("highlightPanel").fireRefresh();
    }
})