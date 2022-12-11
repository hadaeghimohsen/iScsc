SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[FIND_POS_U]
(
	@PosDir VARCHAR(3), 
	@FileNo BIGINT
)
RETURNS BIGINT
AS
BEGIN
	-- Local Var
	DECLARE @LeftFileNo BIGINT,
	        @RighFileNo BIGINT;
	        
	DECLARE @FinlFileNo BIGINT = @FileNo;
	
	WHILE(1=1)
	BEGIN
	   SELECT @LeftFileNo = LEFT_FILE_NO, 
	          @RighFileNo = RIGH_FILE_NO
	     FROM dbo.Fighter
	    WHERE FILE_NO = @FileNo;
	   
	   IF @PosDir = '001' -- Left
	      IF @LeftFileNo IS NOT NULL
	         SELECT @FileNo = @LeftFileNo;
	      ELSE
	      BEGIN 
	         SET @FinlFileNo = @FileNo;
	         BREAK;
	      END 
	   ELSE IF @PosDir = '002' -- Right
	      IF @RighFileNo IS NOT NULL	      
	         SELECT @FileNo = @RighFileNo;
	      ELSE
	      BEGIN
	         SET @FinlFileNo = @FileNo;
	         BREAK;
	      END 
	END 
	
	RETURN @FinlFileNo;
END
GO
