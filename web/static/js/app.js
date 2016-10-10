import "phoenix_html";

import DiffController from './controllers/diff-controller';

angular.module('phoenixDiff', [
  "ngAnimate"
])
  .controller("DiffController", DiffController);
