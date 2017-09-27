SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GLR_ACTN_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
   DECLARE @FileNo BIGINT
          ,@Rqid   BIGINT;
   SELECT @FileNo = @X.query('//Request_Row').value('(Request_Row/@fighfileno)[1]', 'BIGINT');
	EXEC dbo.GLR_TRQT_P @X = @X -- xml
	
	--SELECT @Rqid = Rqst_Rqid FROM dbo.Fighter WHERE File_No = @FileNo;
	SELECT @Rqid = r.RQID
	  FROM dbo.Request r, dbo.Request_Row rr
	 WHERE r.RQID = rr.RQST_RQID
	   AND rr.FIGH_FILE_NO = @FileNo
	   AND r.RQTP_CODE = '020'
	   AND r.RQTT_CODE = '004'
	   AND r.RQST_STAT = '001';
	
	SET @X.modify('replace value of (/Process/Request/@rqid)[1] with sql:variable("@Rqid")');
	EXEC dbo.GLR_TSAV_P @X = @X -- xml
END
GO
