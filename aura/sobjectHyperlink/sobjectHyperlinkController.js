({
	navigateToSObject : function(component, event, helper) {
		var sObjId = component.get("v.sObjectId");          
        var navToSObjEvt = $A.get("e.force:navigateToSObject");
        navToSObjEvt.setParams({
            recordId: sObjId,
            slideDevName: "detail"
        });	
        navToSObjEvt.fire(); 
	}
})