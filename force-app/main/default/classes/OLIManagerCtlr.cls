/* Controller for CalculateOLIQuantity Visualforce Component
* RA, 03/07/2020
*/
public class OLIManagerCtlr{
    public Id opportunityId {get;set;}
    public List<OpportunityLineItem> getoppLines()
    {
        List<OpportunityLineItem> oppli;
        oppli = [SELECT Product2.Name, Quantity, OpportunityId 
                 FROM OpportunityLineItem WHERE OpportunityId =: opportunityId];
        return oppli;
    }
}