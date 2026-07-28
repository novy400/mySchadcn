/* eslint-disable prettier/prettier */
import EmployeeIcon from "@mui/icons-material/Group";
import ServiceIcon from "@mui/icons-material/Business";

import {
  Admin,
  Resource
} from "react-admin";
import { Layout } from "./Layout";
import { dataProvider } from "./dataProvider";
import { EmployeeList } from "./composants/employee/EmployeeList";
import { EmployeeShow } from "./composants/employee/EmployeeShow";
import { EmployeeEdit } from "./composants/employee/employeeEdit";
import { ServiceList } from "./composants/service/ServiceList";
import { ServiceShow } from "./composants/service/ServiceShow";
import { ServiceEdit } from "./composants/service/ServiceEdit";
export const App = () => (
  <Admin layout={Layout} dataProvider={dataProvider}>
    <Resource
      name="employees"
      list={EmployeeList}
      edit={EmployeeEdit}
      show={EmployeeShow}
      icon={EmployeeIcon}
    />
    <Resource
      name="services"
      list={ServiceList}
      edit={ServiceEdit}
      show={ServiceShow}
      icon={ServiceIcon}
      recordRepresentation={(service) => `${service.nom}`}
    />
  </Admin>
);
