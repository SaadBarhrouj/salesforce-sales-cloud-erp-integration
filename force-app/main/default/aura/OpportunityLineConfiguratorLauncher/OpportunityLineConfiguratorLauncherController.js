({
    // Runs when the component is first initialized (like on a full page refresh).
    doInit : function(component, event, helper) {
        var pageRef = component.get("v.pageReference");
        
        if (pageRef && pageRef.state) {
            var recId = pageRef.state.c__recordId;
            
            if (recId) {
                component.set("v.recordId", recId);
            }
        }
    },

    // Runs when the URL changes but the page does NOT fully reload.
    onPageReferenceChange: function(component, event, helper) {
        var pageRef = component.get("v.pageReference");

        if (pageRef && pageRef.state && pageRef.state.c__recordId) {
            component.set("v.recordId", pageRef.state.c__recordId);
        }
    }
})