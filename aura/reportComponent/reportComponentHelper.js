({
    getReportsForSearch : function(component) {
        var action = component.get("c.getReportsForSearch");
        var self = this;
        action.setCallback(this, function(a){
			var reportList = a.getReturnValue();
            component.set("v.reportList", reportList);

            // Display toast message to indicate load status
            var toastEvent = $A.get("e.force:showToast");
            if(action.getState() ==='SUCCESS'){
                toastEvent.setParams({
                    "title": "Ready",
                    "duration": 500
                });
            }else{
                toastEvent.setParams({
                    "title": "Error!"
                });
            }
            toastEvent.fire();
        });
         $A.enqueueAction(action);
    },    
    
    getReportResponse : function(component, event, helper) {
        var action = component.get("c.getReportResponse");
		var report = event.getParam("report");
        action.setParams({"reportId": report.Id});
        action.setCallback(this, function(a){
			var reportResponseObj = JSON.parse(a.getReturnValue());
            
            console.log('reportResponseObj');
            console.log(reportResponseObj);
            
            component.set("v.tabResp", reportResponseObj.tabResp);
            component.set("v.sumResp", reportResponseObj.sumResp);
            component.set("v.reportResponse", reportResponseObj);
            
            // Display toast message to indicate load status
            var toastEvent = $A.get("e.force:showToast");
            if(action.getState() ==='SUCCESS'){
                toastEvent.setParams({
                    "title": "Report Loaded.",
                    "duration": 500
                });
            }else{
                toastEvent.setParams({
                    "title": "Error!",
                    "message": " Something has gone wrong."
                });
            }
            toastEvent.fire();
        });
         $A.enqueueAction(action);
    },
    
 	loadResources : function() {
        this.loadJS('/resource/jquery_mobile_145/jquery-1.11.2.min.js', '/resource/jquery_mobile_145/jquery.mobile-1.4.5.min.js', function() {
			console.log('jquery loaded');
        });  
    	this.loadCSS('/resource/jquery_mobile_145/jquery.mobile-1.4.5.min.css', function() {
			console.log('css loaded');
        }); 
    	this.loadCSS('/resource/jquery_mobile_145/custom.css', function() {
			console.log('css loaded');
        });          
    },
    loadCSS : function(source, callback) {
        var fileref = document.createElement('link');
        fileref.setAttribute("rel", "stylesheet");
        fileref.setAttribute("type", "text/css");
        fileref.setAttribute("href", source);
        fileref.onload = callback;
        document.head.appendChild(fileref);
    }, 
    loadJS : function(source1, source2, callback) {
        var loadScript = document.createElement('script');
        loadScript.setAttribute('src', source1);
        document.head.appendChild(loadScript);
        setTimeout(function(){
            loadScript = document.createElement('script');
            loadScript.setAttribute('src', source2);
            loadScript.onload = callback;
            document.head.appendChild(loadScript);          
        }, 100);        
    }
   
})