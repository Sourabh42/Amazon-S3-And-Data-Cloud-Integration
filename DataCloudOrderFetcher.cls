public without sharing class DataCloudOrderFetcher {
    // Input parameters passed from Agentforce
    public class RequestParameters {
        @InvocableVariable(required=true label='customerEmail' description='The Salesforce CustomerEmail')
        public String customerEmail;
    }

    // Output parameters returned back to Agentforce
    public class ResponseWrapper {
        @InvocableVariable(label='Order Information' description='Summary of the customer orders')
        public String orderSummary;
    }

    @InvocableMethod(label='Get Customer Orders' description='Retrieves order information for a given Contact ID')
    public static List<ResponseWrapper> getOrders(List<RequestParameters> requestParam) {
        
        String email = requestParam[0].customerEmail;
        
        List<Contact> contactRec =[Select Id,Title from Contact where Email =: email];
        String ContactId = contactRec[0].Id;
        List<ResponseWrapper> responses = new List<ResponseWrapper>();
        
        // query on UnifiedIndividualLinkRecord by using contactId
      List<UnifiedLinkssotIndividual2__dlm> record1 =  [SELECT CreatedDate__c, ssot__DataSourceId__c, ssot__DataSourceObjectId__c, SourceRecordId__c, 
           												ssot__InternalOrganizationId__c, UnifiedRecordId__c FROM UnifiedLinkssotIndividual2__dlm 
                                                        WHERE SourceRecordId__c =: ContactId];
        
        String unifiedRecordId = record1[0].UnifiedRecordId__c;
        
        List<UnifiedLinkssotIndividual2__dlm> record2 = [SELECT CreatedDate__c, ssot__DataSourceId__c, ssot__DataSourceObjectId__c, SourceRecordId__c, 
           												ssot__InternalOrganizationId__c, UnifiedRecordId__c FROM 
                                                         UnifiedLinkssotIndividual2__dlm WHERE SourceRecordId__c !=: ContactId
                                                        AND UnifiedRecordId__c =: unifiedRecordId];
        
        String S3RecordId = record2[0].SourceRecordId__c;
        
        List<ssot__SalesOrder__dlm> listOfOrderPurchase = [SELECT ssot__DataSourceId__c, ssot__DataSourceObjectId__c, 
                                                           ssot__InternalOrganizationId__c, KQ_Id__c, 
                                                        ssot__PurchaseOrderDate__c, ssot__Id__c, ssot__SalesOrderStatusId__c, ssot__SoldToCustomerId__c, 
                                                        ssot__TotalAmount__c FROM ssot__SalesOrder__dlm where ssot__SoldToCustomerId__c =: S3RecordId];
        
        ResponseWrapper res = new ResponseWrapper();
        if (!listOfOrderPurchase.isEmpty()) {
                String summary = 'Here are the recent orders for this customer:\n';
                for (ssot__SalesOrder__dlm ord : listOfOrderPurchase) {
                    summary += '- Order #: ' + ord.ssot__Id__c + 
                               ', Status: ' + ord.ssot__SalesOrderStatusId__c + 
                               ', Amount: ' + ord.ssot__TotalAmount__c + 
                               ', Date: ' + ord.ssot__PurchaseOrderDate__c + '\n';
                }
                res.orderSummary = summary;
        } else {
            res.orderSummary = 'No orders found for this customer.';
        }
        responses.add(res);
        return responses;
    }
}
