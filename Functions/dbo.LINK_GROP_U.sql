SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[LINK_GROP_U]
(
	@PGropCode BIGINT, -- گروه کالایی که به عنوان ورودی داده شده
	@TGropCode BIGINT  -- گروه بالاسری که مشخص کند آیا گروه اولی زیر مجموعه گروه دومی میباشد یا خیر	
)
RETURNS BIT
AS
BEGIN
	IF @PGropCode = @TGropCode
	   RETURN 1;
	
	L$LOOP:
	SELECT @PGropCode = ge.GEXP_CODE
	  FROM dbo.Group_Expense ge
	 WHERE ge.CODE = @PGropCode;
	
	IF @PGropCode = @TGropCode
	   RETURN 1;
	
	IF @PGropCode IS NULL
	   RETURN 0;
	
	GOTO L$Loop;
	
	RETURN 0;
END
GO
