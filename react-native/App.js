import React, { Component } from "react";
import FlashMessage from "react-native-flash-message";
import Routes from "./src/Navigation/Routes";
import { LogBox } from "react-native";

//  Recommit for commit standard (Sign off)

LogBox.ignoreAllLogs();
export default class App extends Component {

	render() {
		return (
			<React.Fragment>
				<Routes />
				<FlashMessage position="top" />
			</React.Fragment>
		);
	}
}
