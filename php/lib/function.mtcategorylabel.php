<?php
# Movable Type (r) (C) 2001-2016 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

function smarty_function_mtcategorylabel($args, &$ctx) {
    require_once("MTUtil.php");
    $cat = get_category_context($ctx);
    if (!$cat) return '';
    return $cat->category_label;
}
?>
