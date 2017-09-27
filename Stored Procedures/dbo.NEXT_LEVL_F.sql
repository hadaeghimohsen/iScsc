SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[NEXT_LEVL_F]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	DECLARE @Rqid BIGINT
	       ,@MsttCode SMALLINT
	       ,@SsttCode SMALLINT;
	       
	SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]', 'BIGINT')
	      ,@MsttCode = @X.query('//Request').value('(Request/@msttcode)[1]', 'SMALLINT')
	      ,@SsttCode = @X.query('//Request').value('(Request/@ssttcode)[1]', 'SMALLINT');
	
	UPDATE Request
	   SET SSTT_CODE = @SsttCode
	      ,SSTT_MSTT_CODE = @MsttCode
	 WHERE RQID = @Rqid;
END
GO
