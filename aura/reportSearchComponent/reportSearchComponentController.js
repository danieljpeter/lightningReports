({
    showReport : function(component, event, helper) {
	 	var report = component.get("v.report");        
		var rLoadEvent = $A.get("e.LIGHTNINGREPORT:reportLoadEvent");
		rLoadEvent.setParams({"report": report});
		rLoadEvent.fire();
    }  
})