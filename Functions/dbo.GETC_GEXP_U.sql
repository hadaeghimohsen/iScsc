SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GETC_GEXP_U]
(
	@Code BIGINT
)
RETURNS BIGINT
AS
BEGIN
	-- Declare the return variable here
	DECLARE @GexpDesc NVARCHAR(250)
	       ,@GexpCode BIGINT;
   
	-- Add the T-SQL statements to compute the return value here
   L$Loop:
	SELECT @GexpCode = ge.GEXP_CODE
	      ,@GexpDesc = ge.GROP_DESC
	  FROM dbo.Group_Expense ge
	 WHERE ge.CODE = @Code;
	
	IF @GexpCode IS NULL	
      GOTO L$EndLoop;
   
   SET @Code = @GexpCode;    
   GOTO L$Loop;
   L$EndLoop:
	-- Return the result of the function
	RETURN @Code;
END
GO
