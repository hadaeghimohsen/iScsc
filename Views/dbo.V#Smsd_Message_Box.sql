SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[V#Smsd_Message_Box] AS
SELECT DISTINCT PHON_NUMB, CAST(ACTN_DATE AS DATE) AS ACTN_DATE FROM dbo.V#Sms_Message_Box
GO
