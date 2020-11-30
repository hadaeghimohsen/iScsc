SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DEL_GEXP_P]
    @Code BIGINT
AS
BEGIN
    DELETE dbo.Group_Expense
     WHERE CODE = @Code;
END
GO
