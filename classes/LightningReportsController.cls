public class LightningReportsController {
	
	@AuraEnabled
	public static String getReportResponse(Id reportId) {
    	return JSON.serialize(AnalyticsUtils.getReportResponse(reportId));    
	}
    
	@AuraEnabled
	public static List<Report> getReportsForSearch() {
    	return [SELECT Id, Name FROM Report ORDER BY Name];
    }    
    
}