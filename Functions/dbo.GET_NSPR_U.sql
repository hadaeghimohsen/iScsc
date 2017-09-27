SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_NSPR_U]
(
	@X XML
)
RETURNS BIGINT
AS
BEGIN
	DECLARE @Rqid BIGINT
	       ,@NstpType VARCHAR(3)
	       ,@NstpNumb INT
	       ,@PrntRqid BIGINT;
	
	SELECT @Rqid = @X.query('//Request').value('(Request/@rqid)[1]', 'BIGINT')
	      ,@NstpType = @X.query('//Request').value('(Request/@nstptype)[1]', 'VARCHAR(3)')
	      ,@NstpNumb = @X.query('//Request').value('(Request/@nstpnumb)[1]', 'INT');
	
	DECLARE @I INT = 0;
	
	L$LOOP:
	SELECT @PrntRqid = RQST_RQID
	  FROM dbo.Request
	 WHERE RQID = @Rqid;
	
	IF @NstpType = '001' -- نامحدود
	BEGIN
	   IF @PrntRqid IS NULL AND @I = 0
	      RETURN NULL;
	   ELSE IF @PrntRqid IS NULL AND @I > 0
	      RETURN @Rqid;	      
	END
	ELSE IF @NstpType = '002' -- محدود
	BEGIN
	   IF @PrntRqid IS NOT NULL AND @I = @NstpNumb
	      RETURN @PrntRqid;
	   ELSE IF @PrntRqid IS NULL AND @I <= @NstpNumb
	      RETURN @Rqid;
	END
	SET @I = @I + 1;
	SET @Rqid = @PrntRqid;
	GOTO L$LOOP;
	
	RETURN NULL;
END
GO
