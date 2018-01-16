SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_COMA_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	DECLARE @Code BIGINT
	       ,@CompName NVARCHAR(50)
	       ,@ChckDoblAttnStat VARCHAR(3)
	       ,@ChckAttnAlrm VARCHAR(3);
	
	SELECT @Code = @X.query('//Computer_Action').value('(Computer_Action/@code)[1]', 'BIGINT')
	      ,@CompName = @X.query('//Computer_Action').value('(Computer_Action/@compname)[1]', 'NVARCHAR(50)')
	      ,@ChckDoblAttnStat = @X.query('//Computer_Action').value('(Computer_Action/@chckdoblattnstat)[1]', 'VARCHAR(3)')
	      ,@ChckAttnAlrm = @X.query('//Computer_Action').value('(Computer_Action/@chckattnalrm)[1]', 'VARCHAR(3)');
	
	UPDATE dbo.Computer_Action
	   SET COMP_NAME = @CompName
	      ,CHCK_DOBL_ATTN_STAT = @ChckDoblAttnStat
	      ,CHCK_ATTN_ALRM = @ChckAttnAlrm
	 WHERE CODE = @Code;
END
GO
