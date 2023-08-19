SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_LVRU_U]
(
	@Code BIGINT
)
RETURNS REAL
AS
BEGIN
	DECLARE @LvrgValu REAL = 1,
	        @Tmp real;
	
	DECLARE C$Units CURSOR FOR
	   WITH Units (Code, Titl_Desc, level, Ref_Code, lvrg_Valu) 
      AS 
      ( 
        SELECT 
          CODE, 
          TITL_DESC,     
          0 AS LEVEL, 
          REF_CODE,
          LVRG_VALU
        FROM dbo.App_Base_Define 
        WHERE /*REF_CODE is NOT NULL 
          AND*/ ENTY_NAME = 'PRODUCTUNIT_INFO'
          AND CODE = @Code

        UNION ALL 
        SELECT 
          mn.CODE, 
          mn.TITL_DESC,     
          mt.level + 1, 
          mn.Ref_Code,
          mn.LVRG_VALU
        FROM dbo.App_Base_Define mn, Units mt 
        WHERE mn.CODE = mt.Ref_Code
      ) 
      SELECT Units.lvrg_Valu FROM Units;
   
   OPEN [C$Units];
   L$Loop:
   FETCH [C$Units] INTO @Tmp;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndLoop;
   
   SET @LvrgValu *= @Tmp;
   
   GOTO L$Loop;
   L$EndLoop:
   CLOSE [C$Units];
   DEALLOCATE [C$Units];   
	
	RETURN @LvrgValu;
END
GO
