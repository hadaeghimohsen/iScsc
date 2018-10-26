SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[IntegrationSystems]	
AS
BEGIN
	INSERT INTO dbo.Computer_Action( CODE ,COMP_NAME ,CHCK_DOBL_ATTN_STAT ,CHCK_ATTN_ALRM )
	SELECT 0, c.COMP_NAME_DNRM, '001', '001'
	  FROM dbo.V#Computers c
	 WHERE NOT EXISTS(
	       SELECT *
	         FROM dbo.Computer_Action ca
	        WHERE c.COMP_NAME_DNRM = ca.COMP_NAME
	 );
	
END
GO
