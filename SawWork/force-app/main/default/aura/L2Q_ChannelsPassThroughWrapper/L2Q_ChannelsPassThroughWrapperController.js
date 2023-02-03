({
    init: function (component) {
        window.parent.location = '/partners/s/docusigncontainer?recordId=' + component.get("v.recordId");
    }
})