public with sharing class AnalyticsUtils {
	
	
	public static reportResponse getReportResponse(Id reportId) {
		//get the report result
		Reports.ReportResults results = Reports.ReportManager.runReport(reportId, true);
		
		//get the metadata
		Reports.ReportMetadata reportMetadata = results.getReportMetadata();
		
		//find out what type of report it is by looking at the groupings down and groupings across
		Integer groupingsDown = 0;
		Integer groupingsAcross = 0;
		
		List<Reports.GroupingInfo> groupingDownList = reportMetadata.getGroupingsDown();
		List<Reports.GroupingInfo> groupingAcrossList = reportMetadata.getGroupingsAcross();
		
		if (groupingDownList != null) {
			groupingsDown = groupingDownList.size();
		}
		
		if (groupingDownList != null) {
			groupingsAcross = groupingAcrossList.size();
		}		
		
		String reportType = 'tabular';
		if ( (groupingsDown > 0) && (groupingsAcross == 0) ) {
			reportType = 'summary';	
		}
		
		if ( (groupingsDown > 0) && (groupingsAcross > 0) ) {
			reportType = 'matrix';	
		}		
		
		reportResponse rr = new reportResponse();
		rr.reportType = reportType;	
		
		if (reportType == 'tabular') {
			rr.tabResp = getTabularReportResponse(results);
		} else if (reportType == 'summary') {
			rr.sumResp = getSummaryReportResponse(results);
		} else if (reportType == 'matrix') {
			rr.tabResp = getMatrixReportResponse(results);
		}
		
		return rr;
	}

	public static tabularReportResponse getTabularReportResponse(Reports.ReportResults results) {
		tabularReportResponse trr = new tabularReportResponse();
		List<fieldDef> reportFields = new List<fieldDef>();	
		List<List<fieldData>> fieldDataList = new List<List<fieldData>>();	
		
		//get the metadata
		Reports.ReportMetadata reportMetadata = results.getReportMetadata();

		//get a string array of the field names
		List<String> fieldNames = reportMetadata.getDetailColumns();		
		
		//get the extended metadata
		Reports.ReportExtendedMetadata reportExtendedMetadata = results.getReportExtendedMetadata();

		//get the map of the column names to their name and label
		Map<String, Reports.DetailColumn> detailColumnMap = reportExtendedMetadata.getDetailColumnInfo();
		
	
		//loop over the detailColumnMap and get the name, label, and data type
		for (String fieldName: fieldNames) {
			Reports.DetailColumn detailColumn = detailColumnMap.get(fieldName);
			fieldDef fd = new fieldDef();
			fd.fieldName = detailColumn.getName(); 
			fd.fieldLabel = detailColumn.getLabel();
			fd.dataType = detailColumn.getDataType().name();
			reportFields.add(fd);
		}
		
		
		// Get the fact map from the report results
		Reports.ReportFactWithDetails factDetails = (Reports.ReportFactWithDetails)results.getFactMap().get('T!T');		
		
		List<Reports.ReportDetailRow> reportDetailRowList = factDetails.getRows();
		
		//loop over the rows
		for (Reports.ReportDetailRow reportDetailRow: reportDetailRowList) {
			Integer cellCounter = 0;
			List<fieldData> fieldDataRow = new List<fieldData>();
			//loop over the cells in the row
			for (Reports.ReportDataCell reportDataCell: reportDetailRow.getDataCells()) {
				fieldData fd = new fieldData();
				fd.fieldValue = (String)reportDataCell.getValue();
				fd.fieldLabel = (String)reportDataCell.getLabel();
				fd.dataType = reportFields[cellCounter].dataType;
				fd.isHyperLink = isHyperlink(fd.fieldValue);
				cellCounter++;
				fieldDataRow.add(fd);
			}
			
			//add the row to the list
			fieldDataList.add(fieldDataRow);
		}

		trr.reportFields = reportFields;
		trr.fieldDataList = fieldDataList;
		return trr;
	}	
	
	
	
	public static summaryReportResponse getSummaryReportResponse(Reports.ReportResults results) {
		summaryReportResponse srr = new summaryReportResponse();
		List<fieldDef> reportFields = new List<fieldDef>();	
		
		//get the metadata
		Reports.ReportMetadata reportMetadata = results.getReportMetadata();

		//get a string array of the field names
		List<String> fieldNames = reportMetadata.getDetailColumns();		
		
		//get the extended metadata
		Reports.ReportExtendedMetadata reportExtendedMetadata = results.getReportExtendedMetadata();

		//get the map of the column names to their name and label
		Map<String, Reports.DetailColumn> detailColumnMap = reportExtendedMetadata.getDetailColumnInfo();
		
		//get the map of the grouping column names to their name and label
		Map<String, Reports.GroupingColumn> groupingColumnMap = reportExtendedMetadata.getGroupingColumnInfo();		

		//get the grouping column info
		Reports.GroupingInfo groupingInfo = reportMetadata.getGroupingsDown()[0]; //only supports one grouping level
		Reports.GroupingColumn groupingColumnDetail = groupingColumnMap.get(groupingInfo.getName());				
		
		//loop over the detailColumnMap and get the name, label, and data type
		for (String fieldName: fieldNames) {
			Reports.DetailColumn detailColumn = detailColumnMap.get(fieldName);
			fieldDef fd = new fieldDef();
			fd.fieldName = detailColumn.getName(); 
			fd.fieldLabel = detailColumn.getLabel();
			fd.dataType = detailColumn.getDataType().name();
			reportFields.add(fd);
		}
		srr.reportFields = reportFields;
		
		//get the summary grouping down dimension grouping values.  only going 1 level deep
		List<summaryReportGroup> groupList = new List<summaryReportGroup>();
		for (Reports.GroupingValue groupingValue: results.getGroupingsDown().getGroupings()) {
			summaryReportGroup srg = new summaryReportGroup();
			srg.fieldName = groupingColumnDetail.getLabel();			
			srg.fieldValue = (String)groupingValue.getValue();
			srg.fieldLabel = groupingValue.getLabel();
			srg.groupKey = groupingValue.getKey();
			srg.isHyperLink = isHyperlink(srg.fieldValue);
			
			//use our group key to get the group rows from the fact map
			Reports.ReportFactWithDetails factDetails = (Reports.ReportFactWithDetails)results.getFactMap().get(srg.groupKey+'!T');	
			List<Reports.ReportDetailRow> reportDetailRowList = factDetails.getRows();			

			List<List<fieldData>> fieldDataList = new List<List<fieldData>>();
							
			//loop over the rows
			for (Reports.ReportDetailRow reportDetailRow: reportDetailRowList) {
				Integer cellCounter = 0;
				List<fieldData> fieldDataRow = new List<fieldData>();
				//loop over the cells in the row
				for (Reports.ReportDataCell reportDataCell: reportDetailRow.getDataCells()) {
					fieldData fd = new fieldData();
					fd.fieldValue = (String)reportDataCell.getValue();
					fd.fieldLabel = (String)reportDataCell.getLabel();
					fd.dataType = reportFields[cellCounter].dataType;
					fd.isHyperLink = isHyperlink(fd.fieldValue);
					cellCounter++;
					fieldDataRow.add(fd);
				}
				
				//add the row to the list
				fieldDataList.add(fieldDataRow);
			}			
			srg.fieldsInGroup = srr.reportFields.size();			
			srg.fieldDataList = fieldDataList;
			groupList.add(srg);
		}
		srr.groupList = groupList;

		return srr;
	}		
	
	
	
	public static tabularReportResponse getMatrixReportResponse(Reports.ReportResults results) {
		tabularReportResponse trr = new tabularReportResponse();
		List<fieldDef> reportFields = new List<fieldDef>();
		List<List<fieldData>> fieldDataList = new List<List<fieldData>>();		
		
		//get the metadata
		Reports.ReportMetadata reportMetadata = results.getReportMetadata();

		//get a string array of the field names
		List<String> fieldNames = reportMetadata.getDetailColumns();		
		
		//get the extended metadata
		Reports.ReportExtendedMetadata reportExtendedMetadata = results.getReportExtendedMetadata();

		//get the map of the grouping column names to their name and label
		Map<String, Reports.GroupingColumn> detailColumnMap = reportExtendedMetadata.getGroupingColumnInfo();

		//create the reportFields header row from the grouping fields
		
		//first add the grouping down field info
		Reports.GroupingInfo groupingInfoDown = reportMetadata.getGroupingsDown()[0]; //only supports one grouping level
		Reports.GroupingColumn groupingColumnDown = detailColumnMap.get(groupingInfoDown.getName());
		fieldDef fdGroupDown = new fieldDef();
		fdGroupDown.fieldName = groupingColumnDown.getName(); 
		fdGroupDown.fieldLabel = groupingColumnDown.getLabel();
		fdGroupDown.dataType = groupingColumnDown.getDataType().name();
		reportFields.add(fdGroupDown);
		
		//now add all the groupings across
		for (Reports.GroupingValue groupingValue: results.getGroupingsAcross().getGroupings()) {
			fieldDef fd = new fieldDef();
			fd.fieldName = (String)groupingValue.getValue(); 
			fd.fieldLabel = groupingValue.getLabel();
			fd.dataType = 'DOUBLE_DATA';
			reportFields.add(fd);			
		}				
		
		//get the matrix grouping down dimension grouping values.  only going 1 level deep
		List<summaryReportGroup> groupListDown = new List<summaryReportGroup>();
		for (Reports.GroupingValue groupingValue: results.getGroupingsDown().getGroupings()) {
			summaryReportGroup srg = new summaryReportGroup();
			srg.fieldValue = (String)groupingValue.getValue();
			srg.fieldLabel = groupingValue.getLabel();
			srg.groupKey = groupingValue.getKey();
			srg.isHyperLink = isHyperlink(srg.fieldValue);
			groupListDown.add(srg);
		}
		
		//get the matrix grouping across dimension grouping values.  only going 1 level deep
		List<summaryReportGroup> groupListAcross = new List<summaryReportGroup>();
		for (Reports.GroupingValue groupingValue: results.getGroupingsAcross().getGroupings()) {
			summaryReportGroup srg = new summaryReportGroup();
			srg.fieldValue = (String)groupingValue.getValue();
			srg.fieldLabel = groupingValue.getLabel();
			srg.groupKey = groupingValue.getKey();
			srg.isHyperLink = isHyperlink(srg.fieldValue);
			groupListAcross.add(srg);
		}		

		//now we need to do a nested loop of the groupings down and across to get all the data from the fact map
		for (summaryReportGroup down: groupListDown) {
			List<fieldData> fieldDataRow = new List<fieldData>();

			//first cell is the grouping down
			fieldData fd = new fieldData();
			fd.fieldValue = down.fieldValue;
			fd.fieldLabel = down.fieldLabel;
			fd.dataType = 'STRING_DATA';
			fd.isHyperLink = down.isHyperLink;
			fieldDataRow.add(fd);					
			
			for (summaryReportGroup across: groupListAcross) {
				//use our composite down!across key to get values from the fact map
				Reports.ReportFactWithDetails factDetails = (Reports.ReportFactWithDetails)results.getFactMap().get(down.groupKey+'!'+across.groupKey);	
				Reports.SummaryValue summaryValue = factDetails.getAggregates()[0]; //only support 1 set of aggregates
				
				fd = new fieldData();
				fd.fieldValue = (String)(summaryValue.getValue()+'');
				fd.fieldLabel = (String)(summaryValue.getLabel()+'');
				fd.dataType = 'DOUBLE_DATA';
				fieldDataRow.add(fd);						
					
			}
			//add the row to the list
			fieldDataList.add(fieldDataRow);
		}

		trr.reportFields = reportFields;
		trr.fieldDataList = fieldDataList;
		
		return trr;
	}			
	
	
	public static Boolean isHyperlink(String sVal) {
		Boolean isHyperLink = true;
		Id theId;
		try {theId = (Id)sVal;}
		catch (Exception e) {isHyperLink = false;}
		return isHyperLink;
	}	
	
	
	public class reportResponse {
		public String reportType {get; set;}
		public tabularReportResponse tabResp {get; set;}
		public summaryReportResponse sumResp {get; set;}		
		public reportResponse(){}
	}	
	
	
	public class summaryReportResponse {
		public List<fieldDef> reportFields {get; set;}
		public List<summaryReportGroup> groupList {get; set;}
		public summaryReportResponse(){}
	}	
	
	public class summaryReportGroup {
		public String fieldName {get; set;}
		public String fieldValue {get; set;}
		public String fieldLabel {get; set;}
		public String groupKey {get; set;}
		public Boolean isHyperLink {get; set;}	
		public Integer fieldsInGroup {get; set;}					
		public List<List<fieldData>> fieldDataList {get; set;}
		public summaryReportGroup(){}
	}		
	
	
	public class tabularReportResponse {
		public List<fieldDef> reportFields {get; set;}
		public List<List<fieldData>> fieldDataList {get; set;}
		public tabularReportResponse(){}
	}
	
	public class fieldDef {
		public String fieldName {get; set;}
		public String fieldLabel {get; set;}
		public String dataType {get; set;}
		public fieldDef(){}
	}

	public class fieldData {
		public String fieldValue {get; set;}
		public String fieldLabel {get; set;}
		public String dataType  {get; set;}
		public Boolean isHyperLink {get; set;}			
		public fieldData(){isHyperLink=false;}
	}	
		
	
}