SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[V#Report_Action_Parameter] as
SELECT * FROM dbo.Report_Action_Parameter r WHERE r.RPAC_TYPE = '000' AND r.CRET_BY = UPPER(SUSER_NAME());
GO
