SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_FPFC_U]
(
	@X XML
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @FileNo BIGINT,
	        @FetchData VARCHAR(3),
	        @DataType VARCHAR(3),
	        @Rslt NVARCHAR(MAX);
	
	SELECT @FileNo = @x.query('//Request').value('(Request/@fileno)[1]', 'BIGINT'),
	       @DataType = @x.query('//Request').value('(Request/@datatype)[1]', 'VARCHAR(3)'),
	       @FetchData = @x.query('//Request').value('(Request/@fetchdata)[1]', 'VARCHAR(3)');
   
   SELECT @Rslt = (
      SELECT CASE @FetchData 
                  WHEN '002' THEN CASE WHEN id.IMAG IS NULL OR LEN(id.IMAG) < 100 THEN NULL ELSE id.IMAG END
                  ELSE CASE WHEN id.IMAG IS NULL OR LEN(id.IMAG) < 100 THEN '001' ELSE '002' END  
             END 
        FROM dbo.Request_Row rr, dbo.Receive_Document rd, 
             dbo.Request_Document rt, dbo.Image_Document id
       WHERE rr.FIGH_FILE_NO = @FileNo
         AND rr.RQST_RQID = rd.RQRO_RQST_RQID
         AND rr.RWNO = rd.RQRO_RWNO
         AND rd.RQDC_RDID = rt.RDID
         AND rt.DCMT_DSID = (CASE @DataType WHEN '001' /* FingerPrint */ THEN 13980505495708 ELSE 14032589693230/* Face ID */ END)
         AND rd.RCID = id.RCDC_RCID
         AND id.RWNO = 1
   );
   
   RETURN @Rslt;	       
END
GO
