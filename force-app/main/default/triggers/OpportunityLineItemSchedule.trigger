trigger OpportunityLineItemSchedule on OpportunityLineItemSchedule (after insert, after update) 
  {
  integrator_da__.RealTimeExportResult res = integrator_da__.RealTimeExporter.processExport(); 
}