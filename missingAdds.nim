method add*(parent: CsArrayRankSpecifier; item: CsAwaitExpression) =
  echo "in method add*(parent: CsArrayRankSpecifier; item: CsAwaitExpression)"
  todoimplAdd() # TODO(add: CsArrayRankSpecifier, CsAwaitExpression)

method add*(parent: CsUnsafeStatement; item: CsExpressionStatement) =
  echo "in method add*(parent: CsUnsafeStatement; item: CsExpressionStatement)"
  todoimplAdd() # TODO(add: CsUnsafeStatement, CsExpressionStatement)

method add*(parent: CsAnonymousMethodExpression; item: CsUnsafeStatement) =
  echo "in method add*(parent: CsAnonymousMethodExpression; item: CsUnsafeStatement)"
  todoimplAdd() # TODO(add: CsAnonymousMethodExpression, CsUnsafeStatement)

method add*(parent: CsUnsafeStatement; item: CsFixedStatement) =
  echo "in method add*(parent: CsUnsafeStatement; item: CsFixedStatement)"
  todoimplAdd() # TODO(add: CsUnsafeStatement, CsFixedStatement)

