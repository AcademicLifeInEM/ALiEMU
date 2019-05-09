import classNames from 'classnames';
import React, { HTMLProps } from 'react';

import { Intent } from 'utils/constants';
import styles from './button-outlined.scss';

export interface ButtonOutlinedProps extends HTMLProps<HTMLButtonElement> {
    children: string;
    intent?: Intent;
    type?: 'button' | 'reset' | 'submit';
}

const ButtonOutlined = (props: ButtonOutlinedProps): JSX.Element => {
    const { children, className, intent, ...btnProps } = props;
    const classname = classNames(
        styles.buttonOutlined,
        {
            [styles.buttonOutlinedPrimary]: intent === Intent.PRIMARY,
            [styles.buttonOutlinedSecondary]: intent === Intent.SECONDARY,
            [styles.buttonOutlinedDanger]: intent === Intent.DANGER,
            [styles.buttonOutlinedSuccess]: intent === Intent.SUCCESS,
            [styles.buttonOutlinedWarning]: intent === Intent.WARNING,
        },
        className,
    );
    return (
        <button {...btnProps} className={classname}>
            {children}
        </button>
    );
};

export default ButtonOutlined;
