SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[V#Sales]
AS
SELECT  dbo.Request.RQID ,
        dbo.GET_MTOS_U(dbo.Request.RQST_DATE) AS RQST_DATE ,
        dbo.Request.YEAR ,
        SUBSTRING(dbo.Request.CYCL, 2, 2) CYCL ,
        dbo.D$CYCL.DOMN_DESC AS CYCL_DESC ,
        dbo.V#Users.USER_NAME AS CRET_BY ,
        dbo.Request_Type.RQTP_DESC ,
        dbo.Requester_Type.RQTT_DESC ,
        dbo.Method.MTOD_DESC ,
        dbo.Category_Belt.CTGY_DESC ,
        dbo.D$SXTP.DOMN_DESC AS SXTP ,
        dbo.D$RQST.DOMN_DESC AS RQST ,
        dbo.Payment_Detail.EXPN_PRIC * dbo.Payment_Detail.QNTY AS EXPN_PRIC ,
        dbo.Payment_Detail.EXPN_EXTR_PRCT * dbo.Payment_Detail.QNTY AS EXPN_EXTR_PRCT ,
        dbo.Payment_Detail.QNTY ,
        dbo.GET_MTOS_U(dbo.Payment_Detail.ISSU_DATE) AS ISSU_DATE ,
        dbo.Expense.EXPN_DESC ,
        dbo.Club.NAME ,
        dbo.Club_Method.STRT_TIME ,
        dbo.Club_Method.END_TIME ,
        dbo.D$DYTP.DOMN_DESC AS DYTP ,
        dbo.Request_Type.CODE AS RQTP_CODE ,
        dbo.Requester_Type.CODE AS RQTT_CODE
FROM    dbo.Request_Type
        INNER JOIN dbo.Request_Row
        INNER JOIN dbo.Request ON dbo.Request_Row.RQST_RQID = dbo.Request.RQID
        INNER JOIN dbo.Requester_Type ON dbo.Request.RQTT_CODE = dbo.Requester_Type.CODE ON dbo.Request_Type.CODE = dbo.Request.RQTP_CODE
        INNER JOIN dbo.Fighter ON dbo.Request_Row.FIGH_FILE_NO = dbo.Fighter.FILE_NO
        INNER JOIN dbo.Category_Belt ON dbo.Fighter.CTGY_CODE_DNRM = dbo.Category_Belt.CODE
        INNER JOIN dbo.Method ON dbo.Category_Belt.MTOD_CODE = dbo.Method.CODE
        INNER JOIN dbo.D$SXTP ON dbo.Fighter.SEX_TYPE_DNRM = dbo.D$SXTP.VALU
        INNER JOIN dbo.D$RQST ON dbo.Request.RQST_STAT = dbo.D$RQST.VALU
        INNER JOIN dbo.Payment_Detail ON dbo.Request_Row.RQST_RQID = dbo.Payment_Detail.PYMT_RQST_RQID
                                         AND dbo.Request_Row.RWNO = dbo.Payment_Detail.RQRO_RWNO
        INNER JOIN dbo.Expense ON dbo.Payment_Detail.EXPN_CODE = dbo.Expense.CODE
        INNER JOIN dbo.D$CYCL ON dbo.Request.CYCL = dbo.D$CYCL.VALU
        INNER JOIN dbo.V#Users ON dbo.Request.CRET_BY = dbo.V#Users.USER_DB
        INNER JOIN dbo.Club_Method ON dbo.Fighter.CBMT_CODE_DNRM = dbo.Club_Method.CODE
        INNER JOIN dbo.Club ON dbo.Club_Method.CLUB_CODE = dbo.Club.CODE
        INNER JOIN dbo.D$DYTP ON dbo.Club_Method.DAY_TYPE = dbo.D$DYTP.VALU
WHERE   ( dbo.Request.RQST_STAT = '001' )
        OR ( dbo.Request.RQST_STAT = '002' );



GO
EXEC sp_addextendedproperty N'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[46] 4[25] 2[13] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Request_Type"
            Begin Extent = 
               Top = 7
               Left = 8
               Bottom = 161
               Right = 219
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "Request_Row"
            Begin Extent = 
               Top = 82
               Left = 647
               Bottom = 236
               Right = 904
            End
            DisplayFlags = 344
            TopColumn = 9
         End
         Begin Table = "Request"
            Begin Extent = 
               Top = 83
               Left = 273
               Bottom = 237
               Right = 530
            End
            DisplayFlags = 344
            TopColumn = 21
         End
         Begin Table = "Requester_Type"
            Begin Extent = 
               Top = 139
               Left = 31
               Bottom = 293
               Right = 219
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "Fighter"
            Begin Extent = 
               Top = 203
               Left = 425
               Bottom = 357
               Right = 618
            End
            DisplayFlags = 344
            TopColumn = 40
         End
         Begin Table = "Category_Belt"
            Begin Extent = 
               Top = 204
               Left = 207
               Bottom = 358
               Right = 364
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "Method"
            Begin Extent = 
               Top = 205
               Left = 10
               Bottom = 359
               Right = 135
            End
         ', 'SCHEMA', N'dbo', 'VIEW', N'V#Sales', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_DiagramPane2', N'   DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "D$SXTP"
            Begin Extent = 
               Top = 203
               Left = 682
               Bottom = 313
               Right = 870
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "D$RQST"
            Begin Extent = 
               Top = 26
               Left = 649
               Bottom = 136
               Right = 837
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "Payment_Detail"
            Begin Extent = 
               Top = 82
               Left = 990
               Bottom = 236
               Right = 1205
            End
            DisplayFlags = 280
            TopColumn = 19
         End
         Begin Table = "Expense"
            Begin Extent = 
               Top = 82
               Left = 1345
               Bottom = 236
               Right = 1495
            End
            DisplayFlags = 344
            TopColumn = 25
         End
         Begin Table = "D$CYCL"
            Begin Extent = 
               Top = 68
               Left = 25
               Bottom = 178
               Right = 213
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "V#Users"
            Begin Extent = 
               Top = 130
               Left = 669
               Bottom = 216
               Right = 857
            End
            DisplayFlags = 344
            TopColumn = 1
         End
         Begin Table = "Club_Method"
            Begin Extent = 
               Top = 318
               Left = 656
               Bottom = 472
               Right = 845
            End
            DisplayFlags = 344
            TopColumn = 1
         End
         Begin Table = "Club"
            Begin Extent = 
               Top = 318
               Left = 394
               Bottom = 472
               Right = 553
            End
            DisplayFlags = 344
            TopColumn = 2
         End
         Begin Table = "D$DYTP"
            Begin Extent = 
               Top = 319
               Left = 918
               Bottom = 429
               Right = 1106
            End
            DisplayFlags = 344
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 25
         Width = 284
         Width = 1830
         Width = 2565
         Width = 1830
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 2565
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 6855
         Alias = 900
         Table = 1455
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', 'SCHEMA', N'dbo', 'VIEW', N'V#Sales', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=2
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'V#Sales', NULL, NULL
GO
