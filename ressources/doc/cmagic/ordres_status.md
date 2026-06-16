- ajouter une entité order
  * orders
    * id: integer
    * reference: string
    * date: date
    * customer_id: integer
    * basket: [{ product_id: integer, quantity: integer }]
    * total_ex_taxes: float
    * delivery_fees: float
    * tax_rate: float
    * taxes: float
    * total: float
    * status: 'ordered' | 'delivered' | 'canceled'
    * returned: boolean
- aveec une liste 
![1781635094553](image/ordres_status/1781635094553.png)

- en prenant comme reference 
https://github.com/marmelab/shadcn-admin-kit/tree/main/src/demo/orders
https://github.com/marmelab/shadcn-admin-kit/blob/main/src/demo/orders/OrderList.tsx
![1781635205655](image/ordres_status/1781635205655.png)
https://github.com/marmelab/shadcn-admin-kit/blob/main/src/demo/orders/OrderEdit.tsx
et en respectant les conceptds https://marmelab.com/shadcn-admin-kit/
